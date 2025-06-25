#ifndef OPENGLWIDGET_H
#define OPENGLWIDGET_H

#include <QOpenGLWidget>
#include <QOpenGLFunctions_4_6_Core> // Or the version MGL aligns with

// Forward declarations for MGL types if used directly in header
// However, it's better to keep MGL details in the .cpp file (pimpl or direct)
#ifdef USING_MGL_ON_MACOS
// struct GLMContextRec_t; // Forward declare if GLMContext is used as a pointer type
// typedef struct GLMContextRec_t *GLMContext; // Or use the typedef from MGL's headers
#endif

class OpenGLWidget : public QOpenGLWidget, protected QOpenGLFunctions_4_6_Core
{
    Q_OBJECT

public:
    explicit OpenGLWidget(QWidget *parent = nullptr);
    ~OpenGLWidget();

protected:
    void initializeGL() override;
    void resizeGL(int w, int h) override;
    void paintGL() override;

private:
#ifdef USING_MGL_ON_MACOS
    void *m_glmContext;    // Store as void* to avoid MGL headers in this public header
    void *m_mglRenderer;   // Store as void*

    // Shader program and VAO/VBO for MGL path
    unsigned int m_mglShaderProgram;
    unsigned int m_mglVao;
    unsigned int m_mglVbo;

    void initMGLShaders();
    void initMGLBuffers();
#else
    // Standard OpenGL shader program, VAO, VBO
    unsigned int m_shaderProgram;
    unsigned int m_vao;
    unsigned int m_vbo;

    void initOpenGLShaders();
    void initOpenGLBuffers();
#endif

    void cleanup();
};

#endif // OPENGLWIDGET_H
