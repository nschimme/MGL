#include "mainwindow.h"
#include "openglwidget.h" // Will be created next
#include <QVBoxLayout>

// If you were using a .ui file, you would include "ui_mainwindow.h"
// For this example, we'll create the layout programmatically.

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    // , ui(new Ui::MainWindow) // If using .ui file
{
    // ui->setupUi(this); // If using .ui file

    setWindowTitle(tr("Qt MGL Test"));

    m_openglWidget = new OpenGLWidget(this);

    QWidget *centralWidget = new QWidget(this);
    QVBoxLayout *layout = new QVBoxLayout(centralWidget);
    layout->addWidget(m_openglWidget);
    centralWidget->setLayout(layout);

    setCentralWidget(centralWidget);
    resize(800, 600);
}

MainWindow::~MainWindow()
{
    // delete ui; // If using .ui file
}
