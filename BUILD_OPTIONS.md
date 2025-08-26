# 🔧 APM Examples - Advanced Build Options

**Comprehensive compilation scenarios for OpenTelemetry auto-instrumentation testing**

## 🚀 Quick Reference

```bash
# Basic builds
make build           # Production builds (current platform)
make build-dev       # Development builds with race detection
make build-cross     # Cross-platform builds (all architectures)

# Advanced compilation scenarios
make build-static    # Static builds (no external dependencies)
make build-dynamic   # Dynamic builds (with shared libraries)
make build-cgo       # CGO-enabled builds (C interoperability)
make build-ldflags   # Custom LDFLAGS builds (optimized/debug)

# Comprehensive testing suite
make build-comprehensive  # ALL compilation variants
make binaries            # Show all built binaries
```

## 📋 Build Variants Explained

### **1. Production Builds** (`make build`)
- **Purpose**: Standard production binaries
- **Flags**: Default Go build flags
- **Output**: `bin/<service>`
- **Use Case**: Normal deployment and testing

### **2. Development Builds** (`make build-dev`)
- **Purpose**: Development with race condition detection
- **Flags**: `-race`
- **Output**: `bin/<service>-dev`
- **Use Case**: Development and debugging race conditions

### **3. Cross-Platform Builds** (`make build-cross`)
- **Purpose**: Multiple OS/architecture combinations
- **Platforms**: Linux, macOS, Windows (AMD64 & ARM64)
- **Output**: `bin/<service>-<os>-<arch>`
- **Use Case**: Testing across different platforms

### **4. Static Builds** (`make build-static`)
- **Purpose**: Self-contained binaries with no external dependencies
- **Flags**: `CGO_ENABLED=0 -a -ldflags '-extldflags "-static" -s -w'`
- **Output**: `bin/<service>-static`
- **Use Case**: Container deployments, isolated environments

### **5. Dynamic Builds** (`make build-dynamic`)
- **Purpose**: Binaries that use shared system libraries
- **Flags**: `CGO_ENABLED=1 -ldflags '-linkmode external'`
- **Output**: `bin/<service>-dynamic`
- **Use Case**: System integration, shared library testing

### **6. CGO Builds** (`make build-cgo`)
- **Purpose**: C interoperability enabled with race detection
- **Flags**: `CGO_ENABLED=1 -race`
- **Output**: `bin/<service>-cgo`
- **Use Case**: C library integration, advanced debugging

### **7. LDFLAGS Builds** (`make build-ldflags`)
- **Purpose**: Custom linker flags for different optimization levels
- **Variants**:
  - **Optimized**: `-ldflags '-s -w -X main.buildType=optimized'`
  - **Debug**: `-ldflags '-X main.buildType=debug' -gcflags='-N -l'`
  - **Profile**: `-ldflags '-X main.buildType=profile'`
- **Output**: `bin/<service>-optimized`, `bin/<service>-debug`, `bin/<service>-profile`
- **Use Case**: Performance testing, debugging, profiling

## 🎯 OpenTelemetry Testing Scenarios

### **Static vs Dynamic Linking**
- **Static**: Test auto-instrumentation in containerized environments
- **Dynamic**: Test with system-level OpenTelemetry libraries

### **CGO Enabled vs Disabled**
- **CGO Enabled**: Test with C-based instrumentation libraries
- **CGO Disabled**: Test pure Go instrumentation

### **Optimization Levels**
- **Optimized**: Test production performance with instrumentation
- **Debug**: Test instrumentation with full debugging symbols
- **Profile**: Test with profiling-enabled instrumentation

### **Cross-Platform**
- Test OpenTelemetry auto-instrumentation across different architectures
- Validate instrumentation consistency across platforms

## 📊 Binary Size Comparison

| Service | Production | Static | Debug | Optimized |
|---------|------------|--------|-------|-----------|
| db-sql-multi | 7.0MB | 7.0MB | 10.4MB | 7.1MB |
| grpc-server | 10.3MB | 10.3MB | 15.4MB | 10.4MB |
| grpc-client | 11.7MB | 11.8MB | 17.6MB | 11.9MB |
| http-rest-api | 6.4MB | 6.4MB | 9.5MB | 6.5MB |
| kafka-producer | 7.2MB | 7.2MB | 10.8MB | 7.3MB |
| kafka-consumer | 6.5MB | 6.5MB | 9.7MB | 6.5MB |

## 🚀 Complete Command Reference

### **Build Commands**
```bash
# Basic builds
make build           # Production builds (current platform)
make build-dev       # Development builds with race detection
make build-cross     # Cross-platform builds (all architectures)
make build-all       # All build types (dev + cross-platform)

# Advanced builds
make build-static      # Static builds (no external dependencies)
make build-dynamic     # Dynamic builds (with shared libraries)
make build-cgo         # CGO-enabled builds (C interop)
make build-ldflags     # Custom LDFLAGS builds (optimized/debug/profile)
make build-comprehensive # ALL compilation variants (testing suite)
```

### **Run Commands (by Build Variant)**
```bash
# Production & Development
make run               # Run production builds
make run-dev           # Run development builds (race detection)

# Cross-platform & Combined
make run-cross         # Run cross-platform builds (current OS)
make run-all           # Run all builds (dev + cross)

# Linking Variants
make run-static        # Run static builds (no dependencies)
make run-dynamic       # Run dynamic builds (shared libraries)
make run-cgo           # Run CGO builds (C interop)

# Optimization Variants
make run-debug         # Run debug builds (full symbols)
make run-optimized     # Run optimized builds (performance)
make run-profile       # Run profile builds (profiling enabled)

# Comprehensive Testing
make run-comprehensive # Run comprehensive test suite (ALL variants)
```

### **Stop Commands (by Build Variant)**
```bash
# Production & Development
make stop               # Stop production builds
make stop-dev           # Stop development builds

# Cross-platform & Combined
make stop-cross         # Stop cross-platform builds
make stop-all           # Stop all builds (dev + cross)

# Linking Variants
make stop-static        # Stop static builds
make stop-dynamic       # Stop dynamic builds
make stop-cgo           # Stop CGO builds

# Optimization Variants
make stop-debug         # Stop debug builds
make stop-optimized     # Stop optimized builds
make stop-profile       # Stop profile builds

# Comprehensive Testing
make stop-comprehensive # Stop comprehensive test suite (ALL variants)
```

## 🔍 Usage Examples

```bash
# Build all variants for comprehensive testing
make build-comprehensive

# Check what's available
make binaries

# Test specific OpenTelemetry scenarios
make run-static         # Container-like environment
make ip                 # Get access URLs
curl http://YOUR_IP:8081/trigger-crud
make stop-static

make run-cgo           # C interoperability testing
curl http://YOUR_IP:8082/trigger-produce
make stop-cgo

make run-debug         # Full debugging symbols
curl http://YOUR_IP:8083/trigger-stream
make stop-debug

# Comprehensive testing workflow
make setup build-comprehensive run-comprehensive ip
# Test all services across all build variants
make stop-comprehensive clean
```

## 🎪 Perfect for Testing

✅ **OpenTelemetry Auto-Instrumentation** across compilation scenarios  
✅ **Performance Impact** of instrumentation on different build types  
✅ **Compatibility Testing** across platforms and linking modes  
✅ **Debugging** instrumentation issues with debug builds  
✅ **Production Readiness** with optimized static builds  

---

**All builds are production-ready and perfect for comprehensive OpenTelemetry testing!** 🚀
