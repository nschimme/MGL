#include "openglwidget.h"
#include <QDebug>
#include <QSurfaceFormat>

// Platform-specific includes
#ifdef USING_MGL_ON_MACOS
#include "mgl/include/mgl.h" // Should resolve via include_directories in CMake
#include "mgl/include/MGLContext.h"
#include "mgl/include/MGLRenderer.h" // For CppCreateMGLRenderer...
#include <TargetConditionals.h> // For TARGET_OS_MAC
#if TARGET_OS_MAC
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#endif

// Dummy MGL function forward declarations if not in a shared MGL header yet
// These should ideally come from mgl.h or MGLContext.h
// GLMContext createGLMContext(GLenum format, GLenum type,
//                             GLenum depth_format, GLenum depth_type,
//                             GLenum stencil_format, GLenum stencil_type);
// void MGLsetCurrentContext(GLMContext ctx);
// void MGLswapBuffers(GLMContext ctx);
// void* CppCreateMGLRendererFromContextAndBindToWindow (void *glm_ctx, void *window);

const char* mglVertexShaderSource = R"glsl(
    #version 450 core
    layout (location = 0) in vec3 aPos;
    layout (location = 1) in vec3 aColor;
    out vec3 ourColor;
    void main()
    {
        gl_Position = vec4(aPos, 1.0);
        ourColor = aColor;
    }
)glsl";

const char* mglFragmentShaderSource = R"glsl(
    #version 450 core
    in vec3 ourColor;
    out vec4 FragColor;
    void main()
    {
        FragColor = vec4(ourColor, 1.0f);
    }
)glsl";

#else // Not on macOS, use standard OpenGL
#include <QOpenGLShaderProgram>

const char* openglVertexShaderSource = R"glsl(
    #version 460 core
    layout (location = 0) in vec3 aPos;
    layout (location = 1) in vec3 aColor;
    out vec3 ourColor;
    void main()
    {
        gl_Position = vec4(aPos, 1.0);
        ourColor = aColor;
    }
)glsl";

const char* openglFragmentShaderSource = R"glsl(
    #version 460 core
    in vec3 ourColor;
    out vec4 FragColor;
    void main()
    {
        FragColor = vec4(ourColor, 1.0f);
    }
)glsl";

#endif


OpenGLWidget::OpenGLWidget(QWidget *parent) : QOpenGLWidget(parent)
#ifdef USING_MGL_ON_MACOS
    , m_glmContext(nullptr)
    , m_mglRenderer(nullptr)
    , m_mglShaderProgram(0)
    , m_mglVao(0)
    , m_mglVbo(0)
#else
    , m_shaderProgram(0)
    , m_vao(0)
    , m_vbo(0)
#endif
{
    QSurfaceFormat format;
    format.setDepthBufferSize(24);
    format.setStencilBufferSize(8);
    format.setVersion(4, 6); // Request OpenGL 4.6
    format.setProfile(QSurfaceFormat::CoreProfile);
    setFormat(format);

    qDebug() << "OpenGLWidget constructor: Requested format" << format;
}

OpenGLWidget::~OpenGLWidget()
{
    cleanup();
}

void OpenGLWidget::initializeGL()
{
    qDebug() << "Initializing OpenGLWidget...";
#ifdef USING_MGL_ON_MACOS
    qDebug() << "Using MGL path on macOS.";

    // 1. Get NSView and NSWindow
    NSView* view = reinterpret_cast<NSView*>(winId());
    if (!view) {
        qCritical() << "Failed to get NSView from QOpenGLWidget.";
        return;
    }
    NSWindow* window = [view window];
    if (!window) {
        qCritical() << "Failed to get NSWindow from NSView.";
        return;
    }

    // 2. Create GLMContext
    // GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV for color
    // GL_DEPTH_COMPONENT, GL_FLOAT for depth
    m_glmContext = createGLMContext(0x80E1, 0x8367, 0x1902, 0x1406, 0, 0);
    if (!m_glmContext) {
        qCritical() << "Failed to create GLMContext.";
        return;
    }
    qDebug() << "GLMContext created:" << m_glmContext;

    // 3. Create MGLRenderer and bind
    // CppCreateMGLRendererFromContextAndBindToWindow expects void* for glm_ctx and window
    m_mglRenderer = CppCreateMGLRendererFromContextAndBindToWindow(m_glmContext, (__bridge void*)window);
    if (!m_mglRenderer) {
        qCritical() << "Failed to create MGLRenderer.";
        // Potentially clean up m_glmContext if its creation was successful but renderer failed
        return;
    }
    qDebug() << "MGLRenderer created and bound:" << m_mglRenderer;

    // 4. Set current context
    MGLsetCurrentContext(static_cast<GLMContext>(m_glmContext));
    qDebug() << "MGL context set current.";

    // Initialize MGL resources (shaders, buffers)
    // Need to use MGL functions (mglCreateShader, mglCompileShader, etc.)
    // For now, this is a placeholder. The actual MGL API for shaders will be used.
    // initializeOpenGLFunctions(); // This is for QOpenGLFunctions, not MGL

    // Check MGL context after setup
    if (MGLgetCurrentContext() != m_glmContext) {
        qWarning() << "MGL context is not current after setup!";
    }

    initMGLShaders();
    initMGLBuffers();

#else // Standard OpenGL path
    qDebug() << "Using standard OpenGL path.";
    if (!initializeOpenGLFunctions()) {
        qCritical() << "Failed to initialize OpenGL functions (QOpenGLFunctions_4_6_Core).";
        return;
    }
    qDebug() << "QOpenGLFunctions_4_6_Core initialized.";

    // Get and print OpenGL version and renderer information
    const GLubyte *ogl_version = glGetString(GL_VERSION);
    const GLubyte *ogl_renderer = glGetString(GL_RENDERER);
    const GLubyte *ogl_vendor = glGetString(GL_VENDOR);
    const GLubyte *ogl_shading_lang_ver = glGetString(GL_SHADING_LANGUAGE_VERSION);

    qDebug() << "OpenGL Version:" << (const char*)ogl_version;
    qDebug() << "OpenGL Renderer:" << (const char*)ogl_renderer;
    qDebug() << "OpenGL Vendor:" << (const char*)ogl_vendor;
    qDebug() << "GLSL Version:" << (const char*)ogl_shading_lang_ver;

    QSurfaceFormat currentFormat = QOpenGLContext::currentContext()->format();
    qDebug() << "Effective QSurfaceFormat: Version" << currentFormat.majorVersion() << "." << currentFormat.minorVersion()
             << "Profile:" << currentFormat.profile();


    initOpenGLShaders();
    initOpenGLBuffers();

    glClearColor(0.1f, 0.1f, 0.2f, 1.0f); // A slightly different clear color for non-MGL
#endif
    qDebug() << "initializeGL finished.";
}

#ifdef USING_MGL_ON_MACOS
void OpenGLWidget::initMGLShaders() {
    GLMContext ctx = static_cast<GLMContext>(m_glmContext);
    if (!ctx) return;
    MGLsetCurrentContext(ctx); // Ensure context is current

    qDebug() << "Initializing MGL shaders...";

    GLuint vertexShader = mglCreateShader(ctx, GL_VERTEX_SHADER);
    mglShaderSource(ctx, vertexShader, 1, &mglVertexShaderSource, NULL);
    mglCompileShader(ctx, vertexShader);

    GLint success;
    mglGetShaderiv(ctx, vertexShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        GLchar infoLog[512];
        mglGetShaderInfoLog(ctx, vertexShader, 512, NULL, infoLog);
        qCritical() << "MGL Vertex Shader compilation failed:" << infoLog;
        mglDeleteShader(ctx, vertexShader);
        return;
    }

    GLuint fragmentShader = mglCreateShader(ctx, GL_FRAGMENT_SHADER);
    mglShaderSource(ctx, fragmentShader, 1, &mglFragmentShaderSource, NULL);
    mglCompileShader(ctx, fragmentShader);

    mglGetShaderiv(ctx, fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        GLchar infoLog[512];
        mglGetShaderInfoLog(ctx, fragmentShader, 512, NULL, infoLog);
        qCritical() << "MGL Fragment Shader compilation failed:" << infoLog;
        mglDeleteShader(ctx, vertexShader); // Also delete previous shader
        mglDeleteShader(ctx, fragmentShader);
        return;
    }

    m_mglShaderProgram = mglCreateProgram(ctx);
    mglAttachShader(ctx, m_mglShaderProgram, vertexShader);
    mglAttachShader(ctx, m_mglShaderProgram, fragmentShader);
    mglLinkProgram(ctx, m_mglShaderProgram);

    mglGetProgramiv(ctx, m_mglShaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        GLchar infoLog[512];
        mglGetProgramInfoLog(ctx, m_mglShaderProgram, 512, NULL, infoLog);
        qCritical() << "MGL Shader Program linking failed:" << infoLog;
    } else {
        qDebug() << "MGL Shaders compiled and linked successfully. Program ID:" << m_mglShaderProgram;
    }

    mglDeleteShader(ctx, vertexShader);
    mglDeleteShader(ctx, fragmentShader);
}

void OpenGLWidget::initMGLBuffers() {
    GLMContext ctx = static_cast<GLMContext>(m_glmContext);
    if (!ctx || m_mglShaderProgram == 0) return;
     MGLsetCurrentContext(ctx);

    qDebug() << "Initializing MGL buffers...";

    // x, y, z, r, g, b
    float vertices[] = {
        // positions         // colors
        -0.5f, -0.5f, 0.0f,  1.0f, 0.0f, 0.0f, // bottom left
         0.5f, -0.5f, 0.0f,  0.0f, 1.0f, 0.0f, // bottom right
         0.0f,  0.5f, 0.0f,  0.0f, 0.0f, 1.0f  // top
    };

    mglGenVertexArrays(ctx, 1, &m_mglVao);
    mglGenBuffers(ctx, 1, &m_mglVbo);

    mglBindVertexArray(ctx, m_mglVao);

    mglBindBuffer(ctx, GL_ARRAY_BUFFER, m_mglVbo);
    mglBufferData(ctx, GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // Position attribute
    mglVertexAttribPointer(ctx, 0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    mglEnableVertexAttribArray(ctx, 0);
    // Color attribute
    mglVertexAttribPointer(ctx, 1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    mglEnableVertexAttribArray(ctx, 1);

    mglBindBuffer(ctx, GL_ARRAY_BUFFER, 0);
    mglBindVertexArray(ctx, 0);
    qDebug() << "MGL Buffers initialized. VAO ID:" << m_mglVao << "VBO ID:" << m_mglVbo;
}

#else // Standard OpenGL init

void OpenGLWidget::initOpenGLShaders() {
    qDebug() << "Initializing Standard OpenGL shaders...";
    QOpenGLShaderProgram *program = new QOpenGLShaderProgram(this); // Managed by this
    if (!program->addShaderFromSourceCode(QOpenGLShader::Vertex, openglVertexShaderSource)) {
        qCritical() << "Vertex shader compilation failed:" << program->log();
        return;
    }
    if (!program->addShaderFromSourceCode(QOpenGLShader::Fragment, openglFragmentShaderSource)) {
        qCritical() << "Fragment shader compilation failed:" << program->log();
        return;
    }
    if (!program->link()) {
        qCritical() << "Shader program linking failed:" << program->log();
        return;
    }
    m_shaderProgram = program->programId(); // Store the ID if needed, or just use the QOpenGLShaderProgram object
    program->bind(); // Bind it for current use, or store and bind in paintGL
    qDebug() << "Standard OpenGL Shaders compiled and linked successfully. Program ID:" << m_shaderProgram;
}

void OpenGLWidget::initOpenGLBuffers() {
    if (m_shaderProgram == 0) return;
    qDebug() << "Initializing Standard OpenGL buffers...";

    float vertices[] = {
        // positions         // colors
        -0.5f, -0.5f, 0.0f,  1.0f, 0.0f, 0.0f,
         0.5f, -0.5f, 0.0f,  0.0f, 1.0f, 0.0f,
         0.0f,  0.5f, 0.0f,  0.0f, 0.0f, 1.0f
    };

    glGenVertexArrays(1, &m_vao);
    glGenBuffers(1, &m_vbo);

    glBindVertexArray(m_vao);

    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // Position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // Color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    qDebug() << "Standard OpenGL Buffers initialized. VAO ID:" << m_vao << "VBO ID:" << m_vbo;
}
#endif


void OpenGLWidget::resizeGL(int w, int h)
{
    qDebug() << "resizeGL called with width" << w << "height" << h;
#ifdef USING_MGL_ON_MACOS
    if (m_glmContext) {
        MGLsetCurrentContext(static_cast<GLMContext>(m_glmContext));
        // MGL Renderer should handle drawable size changes automatically via CAMetalLayer
        // or its binding to the NSWindow/NSView.
        // If not, a specific MGL function would be called here.
        // For now, assume it's automatic.
        // mglViewport(static_cast<GLMContext>(m_glmContext), 0, 0, w, h); // If mglViewport is available and needed
        // The `mglViewport` is part of mgl.h, so it can be called.
        // It's good practice to set viewport.
        GLMContext ctx = static_cast<GLMContext>(m_glmContext);
        if (ctx) {
             mglViewport(ctx, 0, 0, w, h);
             qDebug() << "MGL viewport set to:" << w << h;
        }
    }
#else
    glViewport(0, 0, w, h);
    qDebug() << "Standard OpenGL viewport set to:" << w << h;
#endif
}

void OpenGLWidget::paintGL()
{
#ifdef USING_MGL_ON_MACOS
    if (!m_glmContext || !m_mglRenderer || m_mglShaderProgram == 0 || m_mglVao == 0) {
        qWarning() << "MGL resources not ready for painting.";
        if (m_glmContext) { // Still clear to a default color if context exists
            MGLsetCurrentContext(static_cast<GLMContext>(m_glmContext));
            mglClearColor(static_cast<GLMContext>(m_glmContext), 0.5f, 0.0f, 0.0f, 1.0f); // Red if error
            mglClear(static_cast<GLMContext>(m_glmContext), GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            MGLswapBuffers(static_cast<GLMContext>(m_glmContext));
        }
        return;
    }

    GLMContext ctx = static_cast<GLMContext>(m_glmContext);
    MGLsetCurrentContext(ctx);
    //qDebug() << "Paint MGL: Context" << MGLgetCurrentContext();


    mglClearColor(ctx, 0.2f, 0.0f, 0.2f, 1.0f); // A dark magenta for MGL
    mglClear(ctx, GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    mglUseProgram(ctx, m_mglShaderProgram);
    mglBindVertexArray(ctx, m_mglVao);
    mglDrawArrays(ctx, GL_TRIANGLES, 0, 3);
    mglBindVertexArray(ctx, 0);
    mglUseProgram(ctx, 0);

    MGLswapBuffers(ctx);
    //qDebug() << "MGL frame painted and swapped.";
#else
    if (m_shaderProgram == 0 || m_vao == 0) {
         qWarning() << "Standard OpenGL resources not ready for painting.";
         // Still clear if context is available
         if (QOpenGLContext::currentContext()) {
            glClearColor(0.5f, 0.0f, 0.0f, 1.0f); // Red if error
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
         }
        return;
    }
    // Make sure our context is current if multiple widgets are used, though QOpenGLWidget handles this.
    // makeCurrent(); // QOpenGLWidget does this before calling paintGL

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Get the QOpenGLShaderProgram object if you stored it instead of ID
    // For this example, assuming m_shaderProgram is an ID and we use raw GL calls
    glUseProgram(m_shaderProgram);
    glBindVertexArray(m_vao);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glBindVertexArray(0);
    glUseProgram(0);

    // doneCurrent(); // QOpenGLWidget handles this
    //qDebug() << "Standard OpenGL frame painted.";
    // QOpenGLWidget handles buffer swapping automatically.
#endif
}

void OpenGLWidget::cleanup()
{
    qDebug() << "Cleaning up OpenGLWidget...";
#ifdef USING_MGL_ON_MACOS
    if (m_glmContext) {
        MGLsetCurrentContext(static_cast<GLMContext>(m_glmContext)); // Ensure context is current for cleanup
        if (m_mglShaderProgram) {
            mglDeleteProgram(static_cast<GLMContext>(m_glmContext), m_mglShaderProgram);
            m_mglShaderProgram = 0;
        }
        if (m_mglVao) {
            mglDeleteVertexArrays(static_cast<GLMContext>(m_glmContext), 1, &m_mglVao);
            m_mglVao = 0;
        }
        if (m_mglVbo) {
            mglDeleteBuffers(static_cast<GLMContext>(m_glmContext), 1, &m_mglVbo);
            m_mglVbo = 0;
        }
        // How to properly destroy MGLRenderer and GLMContext?
        // MGLRenderer is an Objective-C object. If CppCreate... returns a +1 retain count obj,
        // it needs release. Or if it's autoreleased, nothing specific.
        // Assume for now it's managed or doesn't need explicit C-side deletion.
        // If m_mglRenderer was an id, it would be `[(id)m_mglRenderer release];`
        // GLMContext might have a destroy function, e.g. destroyGLMContext(m_glmContext);
        // The GLFW example's destroyContextMGL was empty.
        // For now, we only nullify them.
        MGLsetCurrentContext(nullptr); // Release context
    }
    m_mglRenderer = nullptr; // Not deleting, assuming ARC or other management
    m_glmContext = nullptr;  // Not deleting, assuming it's tied to renderer or view lifecycle

#else
    makeCurrent(); // Ensure context is current for cleanup
    if (m_shaderProgram) {
        // If QOpenGLShaderProgram object was stored and parented to 'this', it's auto-deleted.
        // If only ID stored, and created with raw GL:
        glDeleteProgram(m_shaderProgram);
        m_shaderProgram = 0;
    }
    if (m_vao) {
        glDeleteVertexArrays(1, &m_vao);
        m_vao = 0;
    }
    if (m_vbo) {
        glDeleteBuffers(1, &m_vbo);
        m_vbo = 0;
    }
    doneCurrent();
#endif
    qDebug() << "OpenGLWidget cleanup finished.";
}
