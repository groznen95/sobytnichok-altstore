#!/usr/bin/env bash
# Собирает source.json по тому, что лежит в releases/.
#
# Манифест не пишется руками намеренно: размер файла, номер версии и
# минимальная версия iOS должны совпадать с настоящим .ipa. Разошлись —
# AltStore либо не покажет обновление, либо покажет и не поставит, а причину
# будет искать человек, у которого нет ни .ipa, ни Xcode.
#
#     ./tools/build-source.sh              # адрес из git remote
#     ./tools/build-source.sh логин/репо   # или явно, до добавления remote
#
# Адрес берётся из git remote: пока репозиторий не создан и remote не добавлен,
# скрипт честно об этом скажет, а не подставит выдуманный домен.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -ge 1 ]]; then
  slug=$1
else
  remote=$(git remote get-url origin 2>/dev/null || true)
  if [[ -z "$remote" ]]; then
    echo "Нет origin. Либо создайте репозиторий и добавьте его:" >&2
    echo "  git remote add origin git@github.com:ВАШ-ЛОГИН/sobytnichok-altstore.git" >&2
    echo "либо передайте адрес одним аргументом: ./tools/build-source.sh ВАШ-ЛОГИН/sobytnichok-altstore" >&2
    exit 1
  fi
  # git@github.com:user/repo.git и https://github.com/user/repo.git — к user/repo.
  slug=$(sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##' <<<"$remote")
fi
owner=${slug%%/*}
repo=${slug##*/}
base="https://${owner}.github.io/${repo}"

ipa=$(ls -1 releases/*.ipa | sort | tail -1)
size=$(stat -f%z "$ipa")

# Версии читаются из самого .ipa, а не из соседнего файла с числами.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
unzip -qo "$ipa" 'Payload/*.app/Info.plist' -d "$work"
plist=$(find "$work/Payload" -maxdepth 2 -name Info.plist | head -1)
pb() { /usr/libexec/PlistBuddy -c "Print :$1" "$plist"; }
version=$(pb CFBundleShortVersionString)
build=$(pb CFBundleVersion)
minos=$(pb MinimumOSVersion)
bundle=$(pb CFBundleIdentifier)
date=$(date -u +%Y-%m-%d)

shots=$(for f in assets/screenshots/*.png; do
  read -r w h < <(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/{printf "%s ", $2}')
  printf '{"imageURL":"%s/%s","width":%s,"height":%s},' "$base" "$f" "$w" "$h"
done | sed 's/,$//')

python3 - "$base" "$ipa" "$size" "$version" "$build" "$minos" "$bundle" "$date" "$shots" <<'PY'
import json, sys
base, ipa, size, version, build, minos, bundle, date, shots = sys.argv[1:10]

description = (
    "СобытНичок показывает состояние события, а не новости о нём.\n\n"
    "У каждого события в каталоге — одно текущее состояние и одно следующее "
    "действие с датой: заседание назначено на вторник, слушания начнутся "
    "сегодня в 14:00, решение вынесено. Не двадцать заметок об одном и том же, "
    "а ответ на два вопроса: что сейчас и что дальше.\n\n"
    "• Каталог открыт без регистрации. Аккаунт нужен только чтобы подписаться.\n"
    "• Подписки сгруппированы по времени: сегодня, скоро, без даты, завершённые.\n"
    "• Виджет на домашнем экране и на экране блокировки сам считает время до "
    "ближайшего действия — приложение для этого открывать не нужно.\n"
    "• Напоминание приходит один раз, перед назначенным действием, и только "
    "если вы сами выбрали, за сколько предупредить. По умолчанию — не напоминать.\n"
    "• Если известен только день, приложение покажет день, а не выдуманный час. "
    "Если дата не назначена — так и скажет.\n\n"
    "Ленты здесь нет намеренно. Приложение не пытается занять ваше время: вы "
    "открываете его, когда хотите, а не когда вас разбудили."
)

source = {
    "name": "СобытНичок",
    "identifier": "ru.sobytnichok.source",
    "subtitle": "Состояние событий, а не новости о них",
    "description": "Источник с единственным приложением — СобытНичком.",
    "iconURL": f"{base}/assets/icon.png",
    "website": "https://xn--90aogncoj5b7a.xn--p1ai",
    "tintColor": "#0A84FF",
    "nsfw": False,
    "apps": [{
        "name": "СобытНичок",
        "bundleIdentifier": bundle,
        "developerName": "СобытНичок",
        "subtitle": "Что сейчас и что дальше",
        "localizedDescription": description,
        "iconURL": f"{base}/assets/icon.png",
        "tintColor": "#0A84FF",
        "category": "news",
        "screenshots": json.loads(f"[{shots}]"),
        "versions": [{
            "version": version,
            "buildVersion": build,
            "date": date,
            "localizedDescription": "Первая версия.",
            "downloadURL": f"{base}/{ipa}",
            "size": int(size),
            "minOSVersion": minos,
        }],
        "appPermissions": {
            # Общий контейнер с расширением виджета — единственное, что
            # приложение просит у системы заранее. Остальное (уведомления)
            # спрашивается в момент, когда человек сам это включает.
            "entitlements": ["com.apple.security.application-groups"],
            "privacy": {},
        },
    }],
}

with open("source.json", "w", encoding="utf-8") as f:
    json.dump(source, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"source.json: версия {version} ({build}), {int(size)} байт, iOS {minos}+")
print(f"адрес источника: {base}/source.json")
PY
