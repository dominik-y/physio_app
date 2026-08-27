import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/domain/models.dart';

/// Demo-mode stand-in for AuthBloc (spec §15.1): which side of the app the
/// viewer entered as. Null = role gate. The router redirects on changes.
class RoleCubit extends Cubit<UserRole?> {
  /// The Firebase flavor passes the resolved role so the app boots straight
  /// past the gate; demo starts at null (role gate page).
  RoleCubit([super.initial]);

  void enterAs(UserRole role) => emit(role);

  void signOut() => emit(null);
}
