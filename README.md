# Получаем текущее содержимое README.md
$readmeExists = Test-Path README.md
if ($readmeExists) {
$readme = Get-Content -Path README.md -Raw

    # Проверяем, есть ли уже раздел о Firebase
    if ($readme -match "## Настройка Firebase") {
        Write-Host "Раздел о Firebase уже существует в README.md"
    } else {
        $readmeAddition = @"

## Настройка Firebase

Этот проект использует Firebase для аутентификации, базы данных Firestore и хранилища Storage.

### Шаги настройки:

1. Создайте проект в Firebase на [firebase.google.com](https://firebase.google.com/)
2. Зарегистрируйте ваше Android и/или iOS приложение с правильными идентификаторами пакетов
3. Скачайте `google-services.json` для Android и поместите его в `android/app/`
4. Скачайте `GoogleService-Info.plist` для iOS и поместите его в `ios/Runner/`
5. Скопируйте `lib/firebase_options_template.dart` в `lib/firebase_options.dart` и заполните вашими данными Firebase

**Важно**: Файлы конфигурации, содержащие API-ключи, не должны попадать в систему контроля версий.

"@

        $newReadme = $readme + $readmeAddition
        Set-Content -Path README.md -Value $newReadme -Encoding UTF8
        Write-Host "README.md обновлен с инструкциями по Firebase"
    }
} else {
$readme = @"
# Drift Notes

Мобильное приложение для записей о рыбалке.

## Настройка Firebase

Этот проект использует Firebase для аутентификации, базы данных Firestore и хранилища Storage.

### Шаги настройки:

1. Создайте проект в Firebase на [firebase.google.com](https://firebase.google.com/)
2. Зарегистрируйте ваше Android и/или iOS приложение с правильными идентификаторами пакетов
3. Скачайте `google-services.json` для Android и поместите его в `android/app/`
4. Скачайте `GoogleService-Info.plist` для iOS и поместите его в `ios/Runner/`
5. Скопируйте `lib/firebase_options_template.dart` в `lib/firebase_options.dart` и заполните вашими данными Firebase

**Важно**: Файлы конфигурации, содержащие API-ключи, не должны попадать в систему контроля версий.
"@
Set-Content -Path README.md -Value $readme -Encoding UTF8
Write-Host "Создан новый файл README.md с инструкциями по Firebase"
}