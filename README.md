# Lore

Lore is a Flutter app for saving personal memories. See [docs/SPEC.md](docs/SPEC.md)
for the product scope and architecture.

## Run locally

1. Install Flutter stable and enable **Email/Password** and **Google** providers
   in Firebase Console under **Authentication > Sign-in method**.
2. Register a Firebase Web app and copy its configuration values from
   **Project settings > Your apps**.
3. Create a Firebase configuration JSON file **outside this repository**. Use
   the following keys and fill in the values from Firebase:

   ```json
   {
     "apiKey": "from-firebase-console",
     "appId": "from-firebase-console",
     "messagingSenderId": "from-firebase-console",
     "projectId": "from-firebase-console",
     "authDomain": "your-project.firebaseapp.com",
     "storageBucket": "your-project.firebasestorage.app",
     "measurementId": "optional-from-firebase-console",
     "GOOGLE_OAUTH_CLIENT_ID": "optional-native-oauth-client-id",
     "GOOGLE_SERVER_CLIENT_ID": "optional-web-oauth-client-id"
   }
   ```

   Use the same field names shown in Firebase's Web app config. Do not commit
   this file. These values are supplied at launch and are not stored in the
   Dart source.
4. From the project folder, run:

   ```powershell
   flutter pub get
   flutter run -d chrome --dart-define-from-file="C:\path\to\lore-firebase.json"
   ```

   Firebase Console must also list `localhost` under **Authentication >
   Settings > Authorized domains** for local web development.

For Android and iOS, create/register the corresponding Firebase apps and
configure the native Google Sign-In client IDs and platform URL schemes as
described by the Firebase and `google_sign_in` setup guides. When Google
Sign-In is configured without native Firebase config files, add
`GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_SERVER_CLIENT_ID` to the external JSON
configuration file and provide the iOS reversed client ID URL scheme in
`ios/Runner/Info.plist`. Do not add private signing credentials or
service-account files to the repository.

## Check the project

```powershell
dart format lib test
flutter analyze
flutter test
```
# tes-upload
