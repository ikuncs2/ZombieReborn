
local ffi = require("cffi")

ffi.cdef[[
void *CreateInterface(const char *name, int *return);
typedef void *(*CreateInterfaceFn)(const char *name, int *return);
typedef void* FileHandle_t;
typedef int FileFindHandle_t;
typedef enum {
    FILESYSTEM_SEEK_HEAD,
    FILESYSTEM_SEEK_CURRENT = 1,
    FILESYSTEM_SEEK_TAIL = 2
} FileSystemSeek_t;
typedef struct IAppSystem IAppSystem;
typedef struct IBaseFileSystem IBaseFileSystem;
typedef struct IFileSystem IFileSystem;
typedef struct CSysModule CSysModule;
typedef struct CUtlBuffer CUtlBuffer;
typedef struct AppSystemInfo_s
{
    const char* m_pModuleName;
    const char* m_pInterfaceName;
} AppSystemInfo_t;
struct IAppSystem_vft
{
    bool (*Connect)(void *this,  CreateInterfaceFn factory );
    void (*Disconnect)(void *this);
    void * (*QueryInterface)(void *this,  const char *pInterfaceName );
    int (*Init)(void *this);
    void (*Shutdown)(void *this);
    void (*PreShutdown)(void *this);
    const AppSystemInfo_t* (*GetDependencies)(void *this);
    int (*GetTier)(void *this);
    void (*Reconnect)(void *this, CreateInterfaceFn factory, const char* pInterfaceName);
    bool (*IsSingleton)(void *this);
    int (*GetBuildType)(void *this);
};
typedef void *(*FSAllocFunc_t)(const char *, unsigned);
struct IBaseFileSystem_vft
{
    int (*Read)(void *this, void *, int, FileHandle_t);
    int (*Write)(void *this, const void *, int, FileHandle_t);
    FileHandle_t (*Open)(void *this, const char *, const char *, const char *);
    void (*Close)(void *this, FileHandle_t);
    void (*Seek)(void *this, FileHandle_t, int, FileSystemSeek_t);
    unsigned int (*Tell)(void *this, FileHandle_t);
    unsigned int (*Size)(void *this, FileHandle_t);
    unsigned int (*Size2)(void *this, const char *, const char *);
    void (*Flush)(void *this, FileHandle_t);
    bool (*Precache)(void *this, const char *, const char *);
    bool (*FileExists)(void *this, const char *, const char *);
    bool (*IsFileWritable)(void *this, const char *, const char * );
    bool (*SetFileWritable)(void *this, const char *, bool, const char *);
    long (*GetFileTime)(void *this, const char *, const char *);
    bool (*ReadFile)(void *this, const char *, const char *, CUtlBuffer *, int, int, FSAllocFunc_t);
    bool (*WriteFile)(void *this, const char *, const char *, CUtlBuffer *);
    bool (*UnzipFile)(void *this, const char *, const char *, const char *);
};
struct IFileSystem_vft
{
    struct IAppSystem_vft IAppSystem;
    struct IBaseFileSystem_vft IBaseFileSystem;
};
struct IFileSystem
{
    struct IFileSystem_vft *vftptr;
};
]]

function FS_GetInterface()
    local addr = ffi.load("filesystem_stdio").CreateInterface("VFileSystem017", ffi.nullptr)
    local pFileSystem = ffi.cast("IFileSystem *", addr)
    print("Get IFileSystem at "..tostring(pFileSystem))
    return pFileSystem
end

function FS_LoadFileForMe(path)
    g_pFileSystem = g_pFileSystem or FS_GetInterface()
    local fp = g_pFileSystem.vftptr.IBaseFileSystem.Open(g_pFileSystem, path, "rb", ffi.nullptr)
    if fp == ffi.nullptr then
        return 
    end
    g_pFileSystem.vftptr.IBaseFileSystem.Seek(g_pFileSystem, fp, 0, 2)
    local size = g_pFileSystem.vftptr.IBaseFileSystem.Tell(g_pFileSystem, fp)
    local buffer = ffi.new("char[?]", size)
    print("IFileSystem::Open fp= "..tostring(fp) .. " size="..tostring(size))
    g_pFileSystem.vftptr.IBaseFileSystem.Seek(g_pFileSystem, fp, 0, 0)
    g_pFileSystem.vftptr.IBaseFileSystem.Read(g_pFileSystem, buffer, size, fp)
    g_pFileSystem.vftptr.IBaseFileSystem.Close(g_pFileSystem, fp)
    return ffi.string(buffer, size)
end