## Build
Gitlab ci/cd описывается в файле `.gitlab-ci.yml` в формате `yaml`. По умолчанию Gitlab ищет этот файл в корне проекта, путь до .gitlab-ci.yml может быть переопределен в настройках проекта.

В этой части мы настроим первый шаг, на котором будет производиться сборка docker image.

**1. Подготавливаем ci/cd**

Для этого скопируем `.gitlab-ci.yml` в проект `xpaste`, выполнив команду:

```bash
cp ~/slurm/16.CI-CD/1.build/.gitlab-ci.yml ~/xpaste/
```
Добавим файл `.gitlab-ci.yml` в git и запушим изменения, выполнив следующие команды:

```bash
cd ~/xpaste
git add .
git commit -am "init ci/cd; add build stage"
git push
```

**2. Проверка результата**

Для проверки результата необходимо перейти в gitlab в раздел `ci/cd -> pipelines` форка проекта xpaste. 
Можно воспользоваться прямой ссылкой: `https://gitlab.slurm.io/sXXXXXX/xpaste/pipelines`. `sXXXXXX` необходимо заменить на номер своего студента.

В результате все job'ы должны закончиться без ошибок.
