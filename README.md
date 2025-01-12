# skeleton

### Troubleshooting
- Generate boilerplate code:   - `flutter packages pub run build_runner build --delete-conflicting-outputs`
- Some methods to deal with common problems:
    - `flutter doctor` may help you to locate problem
    - `flutter clean` it removes downloaded packages, plugins and builds.
    - `flutter pub upgrade` upgrades packages to latest versions
    - `flutter pub cache repair` sometimes packages cache needs to be clean
- IOS has some problem of its own:
    - When you will face pods problems run those:   
      `pod cache clean --all`   
      `rm -rf ios/Podfile.lock`   
      `rm -rf ios/Pods/`   
      `pod repo update` and `pod install`

## Naming convention
- **methods** should include verb and be clear about action they do.    
  example: getAllPromotions, validateCode.
- **variables and classes** should be noun.   
  example: ApiClient apiClient, String userInput, int debounceTimeInMilliSeconds.
- **bools** should have question prefix like: _is, should._   
  example: isValid, isFirstTimeLogin, shouldFetchNewData,

## Packages

### Utils packages
- **logger**: Use for console logs. It can also display logs directly in device. To change/manage style go to `lib/core/utils/logger.dart`.   
  Docs: https://pub.dev/packages/logger
- **path_provider**: This package provides information about device default storage folder.It is needed to set up local database.   
  Docs: https://pub.dev/packages/path_provider
- **dartz**: functional programing style to Dart. We use Either pattern.  
  Docs: https://pub.dev/packages/dartz
- **device_info_plus**: package to receive information about user device, like system and version.   
  Docs: https://pub.dev/packages/device_info_plus
- **uuid** for creating UUIDs   
  Docs: https://pub.dev/packages/uuid/
- **auto_route** for managing app navigation   
  Docs: https://pub.dev/packages/auto_route

### Widgets & UI Utils
- **cupertino_icons**: Set of IOS default icons.   
  Docs: https://api.flutter.dev/flutter/cupertino/CupertinoIcons-class.html#constants

### Translations
- **intl**: Package to keep and translate all hardcoded content. It allows for using various grammar rules. Files are located at: `lib/core/localization`   
  Docs: https://docs.flutter.dev/development/accessibility-and-localization/internationalization

### Dependency injection
- **get_it**: This packages allow to inject object in any place of widget tree. We use it to initialize cubits, and inject repositories and services.   
  Docs: https://pub.dev/packages/get_it
- **injectable** && **injectable_generator**: Those allow to use @annotations on class level, which registers them with get_it and allows easy injection by generating all necessary boiler code.   
  Docs: https://pub.dev/packages/injectable

### Database
- **objectbox** && **objectbox_generator** **: Flutter multi-platform local NoSQL database.   
  Docs: https://pub.dev/packages/objectbox
  Docs: https://docs.objectbox.io/getting-started
- **cloud_firestore**: Remote NoSQL database.
  Docs: https://pub.dev/packages/cloud_firestore


### Navigator
- **auto_route** && **auto_route_generator**: Pages navigator for Flutter, and boilerplate generator.   
  Docs: https://pub.dev/packages/auto_route


### State management
- **flutter_bloc**: State management tool. It connects pages with business logic kept in Cubit classes. Pages use methods in Cubit and Cubits emits proper app states to be handled by page builder.   
  Docs: https://pub.dev/packages/bloc


### Developers
- **build_runner**: All boilerplate code generator depends on this package to generate files.   
  Docs: https://pub.dev/packages/build_runner
- **flutter_lints**: Package to provide all good Flutter and Dart coding practices. Default rules can be changed in `analysis_options.yaml`   
  Docs: https://pub.dev/packages/flutter_lints

## Changelog
- **1.0.0** **10/01/2025**:
    - Repo creation and initial setup

