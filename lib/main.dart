import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learningfirebase/constants/routes.dart';
import 'package:learningfirebase/services/auth/bloc/auth_bloc.dart';
import 'package:learningfirebase/services/auth/bloc/auth_event.dart';
import 'package:learningfirebase/services/auth/bloc/auth_state.dart';
import 'package:learningfirebase/services/auth/firebase_auth_provider.dart';
import 'package:learningfirebase/views/login_views.dart';
import 'package:learningfirebase/views/notes/create_update_note_view.dart';
import 'package:learningfirebase/views/notes/notes_view.dart';
import 'package:learningfirebase/views/register_view.dart';
import 'package:learningfirebase/views/verify_email_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.blueAccent)),
      home: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(FirebaseAuthProvider()),
        child: const HomePage(),
      ),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        notesRoute: (context) => const NotesView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
        createUpdateNoteRoute: (context) => const CreateUpdateNoteView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(AuthEventInitialize());
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthStateLoggedIn){
        return const NotesView();
      }else if(state is AuthStateNeedsVerification){
        return const VerifyEmailView();
      }else if(state is AuthStateLoggedOut){
        return const LoginView();
      }else{
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
          
        );
      }
    },);


    
  }
}
