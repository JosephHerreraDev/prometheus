# Set identification from install inputs
if [[ -n ${PROMETHEUS_USER_NAME//[[:space:]]/} ]]; then
  git config --global user.name "$PROMETHEUS_USER_NAME"
fi

if [[ -n ${PROMETHEUS_USER_EMAIL//[[:space:]]/} ]]; then
  git config --global user.email "$PROMETHEUS_USER_EMAIL"
fi
