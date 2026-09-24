# СобытНичок — источник для AltStore

Приложение, которое показывает **состояние** события, а не новости о нём.
У каждого события — одно текущее состояние и одно следующее действие с датой.

Этот репозиторий — не исходники, а витрина: манифест источника, сборка `.ipa`
и картинки. Открываете страницу с iPhone, нажимаете кнопку — AltStore
добавляет источник и ставит приложение.

**Требуется:** iPhone с iOS 17 или новее и установленный
[AltStore](https://altstore.io). Подписывает приложение AltStore вашим Apple ID
— здесь лежит неподписанный `.ipa`, как и положено источнику.

## Что где лежит

| Путь | Что это |
|---|---|
| `source.json` | Манифест источника. **Собирается скриптом, руками не правится** |
| `index.html` | Страница с кнопкой «Добавить источник в AltStore» |
| `releases/*.ipa` | Сборки приложения |
| `assets/icon.png` | Иконка источника и приложения, 512×512 |
| `assets/screenshots/` | Снимки экрана |
| `tools/build-source.sh` | Генератор манифеста |
| `tools/make-icon.swift` | Генератор иконки |

## Первая публикация

```bash
git remote add origin git@github.com:ВАШ-ЛОГИН/sobytnichok-altstore.git
./tools/build-source.sh          # запишет source.json по адресу из remote
git add -A && git commit -m "Источник AltStore" && git push -u origin main
```

Затем в настройках репозитория на GitHub: **Settings → Pages → Source:
Deploy from a branch → main / (root)**. Через минуту-другую страница откроется
по адресу `https://ВАШ-ЛОГИН.github.io/sobytnichok-altstore/`, а источник —
по тому же адресу с `/source.json` на конце.

Репозиторий обязан быть **публичным**: AltStore скачивает манифест и `.ipa`
без авторизации, и в закрытом репозитории источник просто не загрузится.

## Новая версия

Собрать неподписанный `.ipa` из основного репозитория проекта:

```bash
cd ~/Desktop/sobytnichok/ios
xcodebuild -project Sobytnichok/Sobytnichok.xcodeproj -scheme Sobytnichok \
  -configuration Release -sdk iphoneos -derivedDataPath /tmp/sobyt-build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build

rm -rf /tmp/sobyt-ipa && mkdir -p /tmp/sobyt-ipa/Payload
cp -R /tmp/sobyt-build/Build/Products/Release-iphoneos/Sobytnichok.app /tmp/sobyt-ipa/Payload/
(cd /tmp/sobyt-ipa && zip -qry Sobytnichok-X.Y.ipa Payload)
```

Положить файл в `releases/`, поднять `MARKETING_VERSION` и
`CURRENT_PROJECT_VERSION` в Xcode-проекте (иначе AltStore не увидит
обновление) и пересобрать манифест:

```bash
./tools/build-source.sh
git add -A && git commit -m "Версия X.Y" && git push
```

`build-source.sh` читает версию, номер сборки, минимальную версию iOS и размер
**из самого `.ipa`**. Это не педантизм: если цифры в манифесте разойдутся с
файлом, AltStore либо не покажет обновление, либо покажет и не поставит, —
а разбираться будет человек, у которого нет ни `.ipa`, ни Xcode.

Скрипт берёт последний по имени файл из `releases/`. Прошлые сборки можно
оставлять: манифест описывает только текущую, старые просто лежат рядом.

## Оговорки

**Срок подписи.** AltStore подписывает приложение вашим Apple ID. У бесплатной
учётной записи подпись живёт 7 дней — дальше приложение нужно обновить
(AltStore делает это сам, если запущен рядом с компьютером). У платной —
год. Это ограничение Apple, а не приложения.

**Виджет.** Общий контейнер с расширением (App Group) — единственное, что
приложение просит у системы заранее. На бесплатной учётной записи AltStore
всё равно ставит и приложение, и расширение виджета.

**Лицензии в репозитории нет.** Значит, по умолчанию — все права защищены.
Если хотите, чтобы код или сборку можно было переиспользовать, добавьте файл
`LICENSE`.

## Приложение

Каталог и подписки живут на сервере `api.событичок.рф`.
[Политика обработки данных](https://xn--90aogncoj5b7a.xn--p1ai/privacy) ·
[Пользовательское соглашение](https://xn--90aogncoj5b7a.xn--p1ai/terms)
