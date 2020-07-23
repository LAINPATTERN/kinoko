
import 'dart:async';
import 'package:ffi/ffi.dart';
import 'array.dart';
import 'callback.dart';
import 'gmap.dart';
import 'dart:ffi';
import 'binds.dart';

Map<int, TypeInfo> _classDB = Map();
Map<Type, TypeInfo> _classRef = Map();
Map<int, Base> _objectDB = Map<int, Base>();

class TypeInfo {
  Type type, superType;
  int ptr;
  Map<String, Function> functions = Map();
  dynamic Function(int) constructor;

  TypeInfo(this.type, this.ptr, this.superType);
}

mixin AutoRelease {
  static List<AutoRelease> _cachePool = List<AutoRelease>();
  static Timer timer;
  int _retainCount = 1;
  bool _destroyed = false;

  control() {
    _retainCount ++;
    if (_retainCount > 0) {
      _cachePool.remove(this);
    }
    return this;
  }

  release() {
    if (_retainCount <= 0) {
      throw Exception("Object already release!");
    }
    _retainCount--;
    if (_retainCount <= 0 && !_cachePool.contains(this)) {
      _cachePool.add(this);
    }

    if (timer == null) {
      timer = Timer.periodic(Duration(milliseconds: 20), _timeUp);
    }
    return this;
  }

  static _timeUp(Timer t) {
    t.cancel();
    List<AutoRelease> copyList = List<AutoRelease>.from(_cachePool);
    _cachePool.clear();
    copyList.forEach((AutoRelease tar){
      tar.destroy();
      tar._destroyed = true;
    });
    timer = null;
  }

  destroy() {
  }

  bool get isDestroyed => _destroyed;
}

class AutoPointer<T extends NativeType> with AutoRelease {
  Pointer<T> ptr;
  AutoPointer(this.ptr) {}

  @override
  destroy() {
    free(ptr);
  }
}

void _toNative(dynamic obj, Pointer<NativeTarget> ret) {
  NativeTarget nt = ret[0];
  if (obj is int) {
    nt.type = TypeInt;
    nt.intValue = obj;
  } else if (obj is double) {
    nt.type = TypeDouble;
    nt.doubleValue = obj;
  } else if (obj is Base) {
    nt.type = TypeObject;
    nt.intValue = obj._id;
  } else if (obj is String) {
    nt.type = TypeString;
    Pointer<Utf8> utf8 = Utf8.toUtf8(obj);
    nt.intValue = utf8.address;
    autorelease(utf8);
  } else if (obj is List) {
    Array arr = Array.allocate(obj);
    _toNative(arr, ret);
    arr.release();
  } else if (obj is Map) {
    GMap map = GMap.allocate(obj);
    _toNative(map, ret);
    map.release();
  } else if (obj is Function) {
    Callback cb = Callback.fromFunction(obj);
    _toNative(cb, ret);
    cb.release();
  } else if (obj is Pointer) {
    nt.type = TypePointer;
    nt.intValue = obj.address;
  } else {
    nt.type = 0;
  }
}

Pointer<NativeTarget> _makeArgv(List<dynamic> argv) {
  Pointer<NativeTarget> argvPtr = allocate<NativeTarget>(count: argv.length);
  for (int i = 0, t = argv.length; i < t; ++i) {
    _toNative(argv[i], argvPtr.elementAt(i));
  }
  return argvPtr;
}

List<dynamic> _convertArgv(Pointer<NativeTarget> argv, int length) {
  List<dynamic> results = List(length);
  for (int i = 0; i < length; ++i) {
    NativeTarget target = argv[i];
    dynamic ret;
    switch (target.type) {
      case TypeInt: {
        ret = target.intValue;
        break;
      }
      case TypeDouble: {
        ret = target.doubleValue;
        break;
      }
      case TypeObject: {
        ret = _objectDB[target.intValue];
        break;
      }
      case TypeString: {
        ret = Utf8.fromUtf8(Pointer<Utf8>.fromAddress(target.intValue));
        break;
      }
      case TypeBoolean: {
        ret = (target.intValue != 0);
        break;
      }
      default: {
        ret = null;
      }
    }
    results[i] = ret;
  }
  return results;
}

void autorelease<T extends NativeType>(Pointer<T> ptr) {
  AutoPointer<T>(ptr).release();
}

void _callClassFromNative(int ptr, Pointer<Utf8> name, Pointer<NativeTarget> argv, int length, Pointer<NativeTarget> result) {
  String fun = Utf8.fromUtf8(name);
  try {
    TypeInfo type = _classDB[ptr];
    if (type != null) {
      Function func = type.functions[fun];
      if (func != null) {
        dynamic ret = Function.apply(func, _convertArgv(argv, length));
        _toNative(ret, result);
      }
    }
  } catch (e) {
    print("Call $fun failed : " + e.toString());
  }
}

void _callInstanceFromNative(int ptr, Pointer<Utf8> name, Pointer<NativeTarget> argv, int length, Pointer<NativeTarget> result) {
  String fun = Utf8.fromUtf8(name);
  try {
    Base ins = _objectDB[ptr];
    dynamic ret = ins.apply(fun, _convertArgv(argv, length));
    _toNative(ret, result);
  }catch (e) {
    print("Call $fun failed : " + e.toString());
  }
}

int _createNativeTarget(int type, int ptr) {
  var typeinfo = _classDB[type];
  if (typeinfo != null) {
    var cons = typeinfo.constructor;
    while (cons == null) {
      var sup = typeinfo.superType;
      if (sup != null) {
        typeinfo = _classRef[sup];
        cons = typeinfo.constructor;
      } else break;
    }
    if (cons != null) {
      _objectDB[ptr] = cons(ptr).release();
      return 0;
    }
  }
  return -1;
}

const ret = -1;
Pointer<NativeFunction<CallHandler>> callClassPointer = Pointer.fromFunction(_callClassFromNative);
Pointer<NativeFunction<CallHandler>> callInstancePointer = Pointer.fromFunction(_callInstanceFromNative);
Pointer<NativeFunction<CreateNative>> createNativeTarget = Pointer.fromFunction(_createNativeTarget, ret);

class Base with AutoRelease {

  Map<String, Function> functions = Map();
  int _id = 0;
  TypeInfo _type;

  dynamic call(String name, { argv: const <dynamic>[]}) {
    if (isDestroyed) {
      throw new Exception("This object(${runtimeType}) is destroyed.");
    }
    Pointer<NativeTarget> argvPtr = _makeArgv(argv);
    Pointer<Utf8> namePtr = Utf8.toUtf8(name);
    Pointer<NativeTarget> resultPtr = callObject(_id, namePtr, argvPtr, argv.length);
    List<dynamic> ret = _convertArgv(resultPtr, 1);

    free(namePtr);
    free(argvPtr);
    freePointer(resultPtr);

    var obj = ret[0];
    return obj;
  }

  static dynamic s_call(Type type, String name, {argv: const <dynamic>[]}) {
    TypeInfo typeInfo = _classRef[type];
    if (typeInfo != null) {
      Pointer<NativeTarget> argvPtr = _makeArgv(argv);
      Pointer<Utf8> namePtr = Utf8.toUtf8(name);
      Pointer<NativeTarget> resultPtr = callClass(typeInfo.ptr, namePtr, argvPtr, argv.length);

      List<dynamic> ret = _convertArgv(resultPtr, 1);

      free(namePtr);
      free(argvPtr);
      freePointer(resultPtr);

      return ret[0];
    }
  }

  void on(String name, Function func) {
    functions[name] = func;
  }

  dynamic apply(String name, List<dynamic> argv) {
    if (functions.containsKey(name)) {
      return Function.apply(functions[name], argv);
    }
    return null;
  }

  Type get aliasType {
    return this.runtimeType;
  }

  void initialize() {
    Type t = this.aliasType;
    while (t != null) {
      if (_classRef.containsKey(t)) {
        _type = _classRef[t];
        break;
      }
      t = Base;
    }
  }

  Base() {
    initialize();
  }

  set id(int v) {
    if (this._id == 0) {
      this._id = v;
    }
  }

  dynamic setID(int v) {
    this.id = v;
    return this;
  }

  void allocate(List<dynamic> argv) {
    Pointer<NativeTarget> argvPtr = _makeArgv(argv);
    _id = createObject(_type.ptr, argvPtr, argv.length);
    free(argvPtr);
    _objectDB[_id] = this;
  }

  static bool setuped = false;

  static TypeInfo reg(Type type, String name, Type superType) {
    if (!setuped) {
      setuped = true;
      setupLibrary(callClassPointer, callInstancePointer, createNativeTarget);
    }
    Pointer<Utf8> pname = Utf8.toUtf8(name);
    int handler = bindClass(pname);
    if (handler != 0) {
      TypeInfo info = TypeInfo(type, handler, superType);
      _classDB[handler] = info;
      _classRef[type] = info;
      free(pname);
      return info;
    } else {
      throw new Exception("Unkown class $type with ${name}");
    }
  }

  void destroy() {
    if (_id != 0) {
      freeObject(_id);
      _objectDB.remove(_id);
      _id = 0;
    }
  }
}

void r(Base b) {if (b != null) b.release();}