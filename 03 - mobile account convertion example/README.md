# \>_  mac admin conference 2023

### Конвертация мобильной учётной записи в локальную

Для того чтобы конвертировать уже настроенную мобильную учётную запись macOS в локальную можно использовать вариант скрипта, описанного в статье [Migrating AD mobile accounts to local user accounts](https://derflounder.wordpress.com/2016/12/21/migrating-ad-mobile-accounts-to-local-user-accounts/).

Вариант скрипта в нашем примере не использует интерактивные запросы в терминале, а вместо этого может использовать специальный инструмент [swiftDialog](https://github.com/swiftDialog/swiftDialog), позволяющий отображать кастомные диалоговые окна для взаимодействия с пользователем.

1. Скачайте swiftDialog [со страницы релизов](https://github.com/swiftDialog/swiftDialog/releases), установите в macOS.

2. После этого можно запустить скрипт [convert_mobile_account_to_local.sh](https://github.com/ya-appleinfra/macadminconference-2023/blob/main/03%20-%20mobile%20account%20convertion%20example/convert_mobile_account_to_local.sh) удобмным вам способом – политикой через ваш MDM или сделать доступным для запуска через Self Service самим пользователем.
