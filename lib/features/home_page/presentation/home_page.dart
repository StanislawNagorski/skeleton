import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/extensions/context_extension.dart';

import '../../../core/injectable/injection.dart';
import 'cubit/home_cubit.dart';

@RoutePage()
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => getIt<HomeCubit>(),
        child: Builder(
          builder: (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(context.localizations.homePage_title),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'You have pushed the button this many times:',
                    ),
                    BlocBuilder<HomeCubit, HomeState>(
                      builder: (context, state) => Text(
                          '${state.counter}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: context.read<HomeCubit>().increment,
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ), // This trailing comma makes auto-formatting nicer for build methods.
            )
        ),
      );
}
