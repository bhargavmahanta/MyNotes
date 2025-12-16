import 'package:bloc/bloc.dart';
import 'package:learningfirebase/services/auth/auth_provider.dart';
import 'package:learningfirebase/services/auth/bloc/auth_event.dart';
import 'package:learningfirebase/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState>{
  /// There should be initial state, so we are using AuthStateLoading as initial state
  AuthBloc(AuthProvider provider) : super(const AuthStateLoading()){
    on<AuthEventInitialize>((event, emit)async {
      await provider.initialize();
      final user = provider.currentUser;
      if (user==null){
        emit(const AuthStateLoggedOut(null));
      }else if(!user.isEmailVerified){
        emit (const AuthStateNeedsVerification());
      }else {
        emit(AuthStateLoggedIn(user));
      }
    });
    //log in
    on<AuthEventLogIn>((event, emit)async {
      final email = event.email;
      final password = event.password;
      try{
        final user = await provider.logIn(email: email, password: password);
        emit(AuthStateLoggedIn(user));
      }on Exception catch(e){
        emit(AuthStateLoggedOut(e));
      }
    });

    //log out
    on<AuthEventLogOut>((event, emit)async{
      try{
        emit(const AuthStateLoading());
        await provider.logOut();
        emit(AuthStateLoggedOut(null));
      }on Exception catch(e){
        emit(AuthStateLogoutFailure(e));
      }
    });
  }

}