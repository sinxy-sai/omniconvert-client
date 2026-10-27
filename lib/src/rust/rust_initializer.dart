import 'rust_initializer_stub.dart'
    if (dart.library.io) 'rust_initializer_io.dart'
    as implementation;

Future<void> initializeRust() => implementation.initializeRust();
