// typedefs.dart

// Define a callback type that takes an int parameter.
import 'entities/note.dart';

typedef VoidCallbackWithNullableIntParameter = void Function(int? value);
typedef SaveNoteCallback = void Function(Note note);
typedef VoidTagTap = void Function(String tag);
