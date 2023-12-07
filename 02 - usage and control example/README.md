# \>_  mac admin conference 2023

### Контроль через app-sso и Bugle

Для контроля состояния залогона в Kerberos SSO удобно использовать macOS [Distributed Notifications](https://developer.apple.com/documentation/foundation/notifications) и сторонний opensource инструмент [Bugle](https://github.com/ABridoux/bugle).

Kerberos SSO поддерживает Distributed Notifications и публикует нотификации о разных событиях, полный перечень можно посмотреть в документации:

- https://www.apple.com/ca/business/docs/site/Kerberos_Single_Sign_on_Extension_User_Guide.pdf


В нашем примере необходимо:

1. Скачать и разместить в удобном доступном месте скрипт [refreshAppSSO.sh](https://github.com/ya-appleinfra/macadminconference-2023/blob/main/02%20-%20usage%20and%20control%20example/refreshAppSSO.sh)

2. Скачать и установить Bugle https://github.com/ABridoux/bugle/releases

3. Настроить Bugle на интересующие нотификации или взять наш пример файла настройки [com.example.bugle-config.plist](com.example.bugle-config.plist) в котором необходимо поменять строку `{path to your script}` на путь до скрипта `refreshAppSSO.sh` или до нужного вам. Сохранить файл конфигурации Bugle также в доступном удобном месте на системе, в нашем примере это `/Library/Preferences/com.example.bugle-config.plist`
4. Скачать и установить в **системную** директорию `/Library/LaunchAgents/` launchd plist файл для запуска Bugle – [com.example.bugle-agent.plist](https://github.com/ya-appleinfra/macadminconference-2023/blob/main/02%20-%20usage%20and%20control%20example/com.example.bugle-agent.plist) в котором описывается вариант запуска ранее установленного Bugle с указанием файла конифгурации.
5. Перезагрузить мак или запустить launch агента вручную: `sudo launchctl load -w /Library/LaunchAgent/com.example.bugle-agent.plist`

После этого в нашем примере Bugle запустится и будет получать нотификации каждый раз когда Kerberos SSO будет сообщать о том что появилась связанность с доменом. В этот момент будет выполняться скрипт, проверяющий залогон пользователя и инициирующий логон если пользователь разлогинен.

### Смена пароля

Для того чтобы ограничить возможность пользователя менять пароль учётной записи штатным способом можно использовать конифгурационный профиль:

- [Restrict Local Password Change.mobileconfig](https://github.com/ya-appleinfra/macadminconference-2023/blob/main/02%20-%20usage%20and%20control%20example/Restrict%20Local%20Password%20Change.mobileconfig)

Загрузите и установите конфигурационный профиль через ваше MDM решение.

### We need to go deeper

Больше информации о состоянии Kerberos SSO можно найти в специальном файле с дополнительными данными в пользовательской директории:

`~/Library/Group Containers/group.com.apple.KerberosExtension/Library/Preferences/group.com.apple.KerberosExtension.plist`

```
$ defaults read /Users/$USER/Library/Group\ Containers/group.com.apple.KerberosExtension/Library/Preferences/group.com.apple.KerberosExtension.plist
{
...
    "MY.COMPANY:dateADPasswordLastChangedWhenSynced" = "2023-08-10 13:44:41";
    "MY.COMPANY:dateExpirationChecked" = "2023-11-24 10:10:06";
    "MY.COMPANY:dateLastLogin" = "2023-11-24 10:10:06";
    "MY.COMPANY:dateLocalPasswordLastChanged" = "2023-08-10 13:44:42";
    "MY.COMPANY:dateLocalPasswordLastChangedWhenSynced" = "2023-08-10 13:44:42";
    "MY.COMPANY:dateNextPacRefresh" = "2023-11-24 13:10:06";
    "MY.COMPANY:datePasswordCanChange" = "2023-08-11 13:44:41";
    "MY.COMPANY:datePasswordExpires" = "2024-08-09 13:44:41";
    "MY.COMPANY:datePasswordLastChanged" = "2023-08-10 13:44:41";
    "MY.COMPANY:datePasswordLastChangedAtLogin" = "2023-08-10 13:44:41";
...
}
```
