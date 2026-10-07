# СобытНичок — источник для AltStore

Приложение показывает **состояние** события, а не новости о нём: что сейчас
и что дальше, с датой.

**Установка:** откройте с iPhone
[страницу источника](https://groznen95.github.io/sobytnichok-altstore/) и
нажмите кнопку. Нужен iOS 17+ и [AltStore](https://altstore.io).

Адрес источника: `https://groznen95.github.io/sobytnichok-altstore/source.json`

## Что где

| Путь | Что это |
|---|---|
| `source.json` | Манифест. Собирается скриптом, руками не правится |
| `index.html` | Страница с кнопкой установки |
| `releases/*.ipa` | Сборки |
| `assets/` | Иконка и снимки экрана |
| `tools/build-source.sh` | Генератор манифеста |
| `assets/icon.png` | Иконка. Копия `AppIcon.png` из приложения, своего генератора здесь нет: две метки по разным числам рано или поздно разойдутся |

## Пересборка

**Версию не поднимать, пока не попросят.** Сейчас 1.1.2 (сборка 4).
AltStore показывает обновление только при росте версии: пересборка той же
версии заменяет файл, но существующей установке не предлагается — её тогда
нужно переустановить вручную.

Версия живёт в `Info.plist` обоих таргетов (`CFBundleShortVersionString` и
`CFBundleVersion`), а не в настройках проекта: правка `MARKETING_VERSION` в
pbxproj ни на что не влияет и тихо собирает старый номер.

```bash
cd ~/Desktop/sobytnichok/ios
xcodebuild -project Sobytnichok/Sobytnichok.xcodeproj -scheme Sobytnichok \
  -configuration Release -sdk iphoneos -derivedDataPath /tmp/sobyt-build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build

rm -rf /tmp/sobyt-ipa && mkdir -p /tmp/sobyt-ipa/Payload
cp -R /tmp/sobyt-build/Build/Products/Release-iphoneos/Sobytnichok.app /tmp/sobyt-ipa/Payload/
(cd /tmp/sobyt-ipa && zip -qry Sobytnichok-1.1.2.ipa Payload)
```

Положить `.ipa` в `releases/`, удалить прошлый и:

Иконку приложения тоже скопировать, если она менялась:

```bash
cp ~/Desktop/sobytnichok/ios/Sobytnichok/Sobytnichok/Resources/\
Assets.xcassets/AppIcon.appiconset/AppIcon.png assets/icon.png
NOTES="Что изменилось в этой версии." ./tools/build-source.sh
git add -A && git commit -m "Пересборка" && git push
```

Без `NOTES` в графу «что нового» уйдёт «Мелкие изменения.».

Скрипт читает версию, сборку, минимальную iOS и размер из самого `.ipa` —
цифры в манифесте не могут разойтись с файлом.

## Оговорки

**Подпись живёт 7 дней** у бесплатной учётной записи Apple: приложение нужно
обновлять, AltStore делает это сам рядом с компьютером. У платной — год.

**Репозиторий обязан быть публичным** — AltStore ходит за манифестом без
авторизации.

Лицензии нет, то есть все права защищены.

[Политика обработки данных](https://xn--90aogncoj5b7a.xn--p1ai/privacy) ·
[Соглашение](https://xn--90aogncoj5b7a.xn--p1ai/terms)
