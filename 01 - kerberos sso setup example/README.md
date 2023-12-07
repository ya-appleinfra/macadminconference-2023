# \>_  mac admin conference 2023

### Apple Kerberos SSO Extension

Kerberos SSO Extension это системный вариант расширяемой функциональности Single Sign-on для приложений на macOS, который позволяет настроить Kerberos SSO для обновления kerberos тикетов и синхронизации паролей локальных учётных записей macOS с учётными записями из Active Directory.

Документация и дополнительные материалы:

- https://support.apple.com/en-al/guide/deployment/depe6a1cda64/web
- https://support.apple.com/en-al/guide/deployment/dep13c5cfdf9/1/web
- https://developer.apple.com/videos/play/tech-talks/301
- https://developer.apple.com/documentation/devicemanagement/extensiblesinglesignon
- https://developer.apple.com/documentation/devicemanagement/extensiblesinglesignonkerberos

[Kerberos SSO Extension Example.mobileconfig](https://github.com/ya-appleinfra/macadminconference-2023/blob/main/01%20-%20kerberos%20sso%20setup%20example/Kerberos%20SSO%20Extension%20Example.mobileconfig) – пример конфигурационного профиля для настройки Kerberos SSO.

В конфигурационном профиле необходимо заменить:

1. Realm на значение для вашего домена

```
<key>Realm</key>
<string>AD.EXAMPLE.COM</string>
```

2. Список доменых имен, на которых необходимо обслуживать kerberos аутентификацию

```
<key>Hosts</key>
<array>
    <string>example.com</string>
    <string>.example.com.</string>
</array>
```

3. [Возможные остальные ключи](https://developer.apple.com/documentation/devicemanagement/extensiblesinglesignonkerberos/extensiondata) из словаря `ExtensionData` в соответствии с желаемым вам поведением Kerberos SSO Extension

4. Заменить индентификаторы профиля из примера на свои

```
<key>PayloadUUID</key>
<string>FD015125-8EA3-4943-A453-23002CBD187C</string>

<key>PayloadIdentifier</key>
<string>com.example.kerberos-sso</string>
```