import sys
import os
import logging
import traceback
import faulthandler
from logging.handlers import RotatingFileHandler
from pathlib import Path
from PySide6.QtCore import QObject, QThread, Signal, Slot, Qt
from PySide6.QtGui import QIcon, QColor, QBrush
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel, QFileDialog, QComboBox, QTableWidget, QTableWidgetItem,
    QHeaderView, QProgressBar, QTextEdit, QMessageBox, QCheckBox)
from subtitle_engine import videos_in, subtitle_exists, search, describe, download

VERSION = "2.1"

def resource_path(relative):
    return Path(getattr(sys, "_MEIPASS", Path(__file__).resolve().parent)) / relative


LOG_DIR = Path.home() / "Legendas-PTBR"
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "legendas.log"
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(threadName)s %(message)s", handlers=[RotatingFileHandler(LOG_FILE, maxBytes=2_000_000, backupCount=2, encoding="utf-8")])
FAULT_FILE = open(LOG_DIR / "falhas-nativas.log", "a", encoding="utf-8")
faulthandler.enable(file=FAULT_FILE, all_threads=True)

def report_exception(exc_type, exc, tb):
    logging.critical("Erro nao tratado", exc_info=(exc_type, exc, tb))
    traceback.print_exception(exc_type, exc, tb, file=FAULT_FILE)
    FAULT_FILE.flush()

sys.excepthook = report_exception


class Worker(QObject):
    log = Signal(str)
    progress = Signal(int, int)
    candidates = Signal(object)
    finished = Signal()

    def __init__(self, paths, automatic, skip_existing):
        super().__init__()
        self.paths = paths
        self.automatic = automatic
        self.skip_existing = skip_existing
        self._cancel_requested = False

    def cancel(self):
        self._cancel_requested = True

    @Slot()
    def run(self):
        try:
            total = len(self.paths)
            for index, path in enumerate(self.paths, 1):
                if self._cancel_requested:
                    self.log.emit("Pesquisa cancelada. Os vídeos restantes não foram processados.")
                    break
                logging.info('Iniciando %s (%s/%s)', path, index, total)
                self.log.emit(f'[{index}/{total}] {path.name}')
                try:
                    if self.skip_existing and subtitle_exists(path):
                        self.log.emit('  Ignorado: legenda externa já existente.')
                        continue
                    logging.info("Pesquisando legenda: %s", path)
                    video, subtitles = search(path)
                    logging.info("Busca retornou %d legendas", len(subtitles))
                    if not subtitles:
                        self.log.emit('  Nenhuma legenda PT-BR encontrada.')
                        continue
                    if self._cancel_requested:
                        self.log.emit("Cancelamento solicitado; download não iniciado.")
                        break
                    if self.automatic:
                        self.log.emit('  Seleção automática: maior pontuação estimada; sincronização não garantida.')
                        dest = download(path, video, subtitles[0], overwrite=False)
                        self.log.emit(f'  Salvo: {dest.name}')
                    else:
                        rows = [describe(sub, video) for sub in subtitles]
                        self.candidates.emit((str(path), video, rows))
                        self.log.emit(f'  {len(rows)} opção(ões) encontradas (máximo de 150 por vídeo).')
                except Exception as exc:
                    logging.exception('Erro durante a busca: %s', path)
                    self.log.emit(f'  Erro: {exc}')
                finally:
                    self.progress.emit(index, total)
        except BaseException:
            logging.exception("Falha fatal no trabalhador")
        finally:
            self.finished.emit()


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle('OmegaSub — Legendas PT-BR')
        self.setWindowIcon(QIcon(str(resource_path('assets/omegasub.png'))))
        self.resize(940, 660)
        self.paths = []
        self.matches = []
        self.thread = None
        self.worker = None
        root = QWidget()
        self.setCentralWidget(root)
        layout = QVBoxLayout(root)
        layout.setSpacing(10)
        title = QLabel('🎬  OmegaSub  ·  Legendas PT-BR')
        title.setStyleSheet('font-size: 24px; font-weight: 700;')
        layout.addWidget(title)
        line = QHBoxLayout()
        self.file_btn = QPushButton('Selecionar vídeos')
        self.folder_btn = QPushButton('Selecionar pasta')
        self.file_btn.clicked.connect(self.pick_files)
        self.folder_btn.clicked.connect(self.pick_folder)
        line.addWidget(self.file_btn)
        line.addWidget(self.folder_btn)
        layout.addLayout(line)
        self.selected = QLabel('Nenhum vídeo selecionado')
        self.selected.setWordWrap(True)
        layout.addWidget(self.selected)
        options = QHBoxLayout()
        options.addWidget(QLabel('Modo:'))
        self.mode = QComboBox()
        self.mode.addItems(['Automático', 'Manual'])
        options.addWidget(self.mode)
        self.skip = QCheckBox('Ignorar vídeos com legenda externa existente')
        self.skip.setChecked(True)
        options.addWidget(self.skip)
        options.addStretch()
        layout.addLayout(options)
        self.start = QPushButton('Buscar legendas')
        self.start.clicked.connect(self.begin)
        action_line = QHBoxLayout()
        action_line.addWidget(self.start)
        self.cancel_btn = QPushButton("Cancelar após a operação atual")
        self.cancel_btn.setEnabled(False)
        self.cancel_btn.clicked.connect(self.request_cancel)
        action_line.addWidget(self.cancel_btn)
        layout.addLayout(action_line)
        self.progress = QProgressBar()
        layout.addWidget(self.progress)
        layout.addWidget(QLabel('Resultados (modo manual):'))
        self.table = QTableWidget(0, 5)
        self.table.setHorizontalHeaderLabels(['Vídeo', 'Provedor', 'Release', 'Idioma', 'Pontuação'])
        self.table.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)
        self.table.horizontalHeader().setSectionResizeMode(2, QHeaderView.ResizeMode.Stretch)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.table.setSelectionMode(QTableWidget.SelectionMode.SingleSelection)
        self.table.setSortingEnabled(False)
        self.table.setAlternatingRowColors(True)
        self.table.verticalHeader().setVisible(False)  # Remove coluna numerada e canto superior esquerdo
        self.table.setStyleSheet("QTableWidget { alternate-background-color: #283144; selection-background-color: #355b95; selection-color: white; } QTableWidget::item { color: #e9edf5; } QTableWidget::item:selected { background: #355b95; color: white; }")
        self.table.setToolTip('Ordenado por compatibilidade estimada; confirme a sincronização no player.')
        layout.addWidget(self.table)
        self.get_selected = QPushButton('Baixar legenda selecionada')
        self.get_selected.clicked.connect(self.download_selected)
        self.get_selected.setEnabled(False)
        layout.addWidget(self.get_selected)
        layout.addWidget(QLabel('Registro:'))
        self.log = QTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumHeight(145)
        layout.addWidget(self.log)
        self.setStyleSheet('''QWidget { background: #171b24; color: #e9edf5; font-size: 13px; }
            QPushButton { background: #344c7d; border: 0; border-radius: 6px; padding: 10px; }
            QPushButton:hover { background: #4565a5; }
            QPushButton:disabled { background: #353945; color: #8e929b; }
            QComboBox, QTableWidget, QTextEdit { background: #222835; border: 1px solid #394154; border-radius: 5px; padding: 4px; }
            QTableWidget { alternate-background-color: #283144; selection-background-color: #355b95; selection-color: #ffffff; gridline-color: #394154; }
            QTableWidget::item { background-color: #222835; color: #e9edf5; }
            QTableWidget::item:alternate { background-color: #283144; color: #e9edf5; }
            QTableWidget::item:selected { background-color: #355b95; color: #ffffff; }
            QHeaderView::section { background: #2c3547; color: #e9edf5; padding: 6px; border: 1px solid #394154; }
            QTableCornerButton::section { background: #2c3547; border: 1px solid #394154; }
            QProgressBar { border: 1px solid #394154; border-radius: 5px; text-align: center; }
            QProgressBar::chunk { background: #5287d7; }''')

    def pick_files(self):
        files, _ = QFileDialog.getOpenFileNames(self, 'Selecionar vídeos', '', 'Vídeos (*.mkv *.mp4 *.avi *.mov *.wmv *.m4v *.ts *.webm)')
        if files:
            self.paths = [Path(x) for x in files]
            self.selected.setText(f'{len(self.paths)} vídeo(s) selecionado(s)')

    def pick_folder(self):
        folder = QFileDialog.getExistingDirectory(self, 'Selecionar pasta')
        if folder:
            self.paths = videos_in(folder)
            self.selected.setText(f'{len(self.paths)} vídeo(s) encontrados em {folder} (incluindo subpastas)')

    def begin(self):
        if not self.paths:
            QMessageBox.information(self, 'Aviso', 'Selecione vídeos ou uma pasta primeiro.')
            return
        self.matches.clear()
        self.table.setRowCount(0)
        self.get_selected.setEnabled(False)
        self.log.append(f"Iniciando processamento de {len(self.paths)} vídeo(s).")
        self.progress.setMaximum(len(self.paths))
        self.progress.setValue(0)
        self.start.setEnabled(False)
        self.cancel_btn.setEnabled(True)
        self.file_btn.setEnabled(False)
        self.folder_btn.setEnabled(False)
        self.thread = QThread()
        self.worker = Worker(self.paths[:], self.mode.currentIndex() == 0, self.skip.isChecked())
        self.worker.moveToThread(self.thread)
        self.thread.started.connect(self.worker.run)
        self.worker.log.connect(self.log.append)
        self.worker.progress.connect(self.update_progress)
        self.worker.candidates.connect(self.add_matches)
        self.worker.finished.connect(self.thread.quit)
        self.thread.finished.connect(self.worker.deleteLater)
        self.thread.finished.connect(self.done)
        self.thread.start()

    def request_cancel(self):
        if self.worker is not None:
            self.worker.cancel()
            self.cancel_btn.setEnabled(False)
            self.log.append("Cancelamento solicitado; aguardando a operação atual terminar...")

    @Slot(object)
    def add_matches(self, result):
        path, video, rows = result
        for item in rows:
            row = self.table.rowCount()
            self.table.insertRow(row)
            self.matches.append((path, video, item['subtitle']))
            for col, value in enumerate((Path(path).name, item['provider'], item['release'], item['language'], str(item['score']))):
                cell = QTableWidgetItem(value)
                cell.setFlags(cell.flags() & ~Qt.ItemFlag.ItemIsEditable)
                cell.setForeground(QBrush(QColor('#e9edf5')))
                cell.setBackground(QBrush(QColor('#222835' if row % 2 == 0 else '#283144')))
                self.table.setItem(row, col, cell)
        self.get_selected.setEnabled(bool(self.matches))
        self.log.append(f'  Exibidas {len(rows)} opções para {Path(path).name} (ordem de compatibilidade estimada).')

    @Slot(int, int)
    def update_progress(self, current, total):
        self.progress.setValue(current)

    @Slot()
    def done(self):
        self.start.setEnabled(True)
        self.cancel_btn.setEnabled(False)
        self.file_btn.setEnabled(True)
        self.folder_btn.setEnabled(True)
        self.log.append('Pesquisa concluída. Verifique a sincronização das legendas no player.')
        self.thread = None
        self.worker = None

    def download_selected(self):
        row = self.table.currentRow()
        if row < 0 or row >= len(self.matches):
            QMessageBox.information(self, 'Aviso', 'Selecione uma linha da tabela.')
            return
        path, video, subtitle = self.matches[row]
        try:
            output = download(path, video, subtitle, overwrite=False)
            self.log.append(f'Legenda salva: {output}')
            QMessageBox.information(self, 'Sucesso', f'Legenda salva em:\n{output}')
        except Exception as exc:
            logging.exception('Erro no download manual')
            self.log.append(f'Falha ao baixar: {exc}')
            QMessageBox.warning(self, 'Erro', str(exc))


def enable_dark_title_bar(window):
    """Solicita barra de titulo escura ao DWM em versoes compativeis do Windows 10/11."""
    if sys.platform != 'win32':
        return False
    try:
        import ctypes
        from ctypes import wintypes
        hwnd = wintypes.HWND(int(window.winId()))
        value = ctypes.c_int(1)
        dwm = ctypes.WinDLL('dwmapi')
        dwm.DwmSetWindowAttribute.argtypes = [wintypes.HWND, wintypes.DWORD, ctypes.c_void_p, wintypes.DWORD]
        dwm.DwmSetWindowAttribute.restype = ctypes.c_long
        for attribute in (20, 19):
            result = dwm.DwmSetWindowAttribute(hwnd, attribute, ctypes.byref(value), ctypes.sizeof(value))
            if result == 0:
                return True
        logging.info('Barra de titulo escura nao suportada por esta versao do Windows')
    except Exception:
        logging.exception('Nao foi possivel configurar barra de titulo escura')
    return False


if __name__ == '__main__':
    logging.info("Aplicativo iniciado")
    if sys.platform == 'win32':
        try:
            import ctypes
            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID('OmegaSub.Desktop')
        except Exception:
            logging.exception('Falha ao configurar identidade da barra de tarefas')
    app = QApplication(sys.argv)
    app.setWindowIcon(QIcon(str(resource_path('assets/omegasub.png'))))
    window = MainWindow()
    window.showMaximized()
    enable_dark_title_bar(window)
    sys.exit(app.exec())
