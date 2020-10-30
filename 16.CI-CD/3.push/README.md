## Push

В этой части к имеющимся шагам добавляем image push в registry. В качестве registry используется gitlab registry. Push выполняется только в случае, если предыдущие шаги закончились успешно.

**1. Подготавливаем ci/cd**

Для этого скопируем `.gitlab-ci.yml` в проект `xpaste`, выполнив команду:

```bash
cp ~/slurm/16.CI-CD/3.push/.gitlab-ci.yml ~/xpaste/
```
Добавим файл `.gitlab-ci.yml` в git и запушим изменения, выполнив следующие команды:

```bash
cd ~/xpaste
git add .
git commit -am "add push stage"
git push
```

**2. Проверка результата**

Для проверки результата необходимо перейти в gitlab в раздел `ci/cd -> pipelines` форка проекта xpaste. 
Можно воспользоваться прямой ссылкой: `https://gitlab.slurm.io/sXXXXXX/xpaste/pipelines`. `sXXXXXX` необходимо заменить на номер своего студента.

В результате все 4 job'а должны закончиться без ошибок.

