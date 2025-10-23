#!/bin/sh

appInstallPath="/Applications"
bundleName="ChatGPT Atlas"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

XML=$(/usr/bin/curl -s "https://persistent.oaistatic.com/atlas/public/sparkle_public_appcast.xml")
currentVers=$(/bin/echo "${XML}" | /usr/bin/xmllint --xpath '//rss/channel/item[1]/title/text()' -)
downloadURL=$(/bin/echo "${XML}" | /usr/bin/xmllint --xpath 'string(//rss/channel/item[1]/enclosure/@url)' -)
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
  installedVersNoDots=$(/bin/echo "${installedVers}" | /usr/bin/sed 's/\.//g')
  currentVersNoDots=$(/bin/echo "${currentVers}" | /usr/bin/sed 's/\.//g')

  # pad out currentVersNoDots to match installedVersNoDots
  installedVersNoDotsCount=${#installedVersNoDots}
  currentVersNoDotsCount=${#currentVersNoDots}

  while [ "${currentVersNoDotsCount}" -lt "${installedVersNoDotsCount}" ]; do
    currentVersNoDots="${currentVersNoDots}0"
    currentVersNoDotsCount=$((currentVersNoDotsCount + 1))
  done

  if [ "${installedVersNoDots}" -ge "${currentVersNoDots}" ]; then
    /bin/echo "${bundleName} does not need to be updated"
    exit 0
  else
    /bin/echo "${bundleName} needs to be updated"
  fi
else
  /bin/echo "Installing ${bundleName}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  /usr/bin/ditto -xk /tmp/"${FILE}" "${appInstallPath}"/.
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /bin/rm /tmp/"${FILE}"
fi

if [ ! "${installedVers}" ]; then
  cat << 'EOF' > /usr/local/bin/apiutil
#!/bin/sh
"/Applications/API Utility.app/Contents/MacOS/apiutil" "$@"
EOF

  /usr/sbin/chown root:wheel /usr/local/bin/apiutil
  /bin/chmod a+x /usr/local/bin/apiutil
fi
