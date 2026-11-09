import 'package:omok/controller/controller.dart';
import 'package:omok/view/ui.dart';

Future<void> main() async {
  await GameController(ConsoleUI()).run();
}