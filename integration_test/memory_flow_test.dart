import 'package:integration_test/integration_test.dart';
import '../test/flows/capture_to_profile_test.dart' as flow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  flow.registerCaptureFlow();
}
