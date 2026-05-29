# [Помощник для работы с контрактами дальнобойщика на проекте Evolve Role Play](https://github.com/SamFredrickson/Truck-Contracts-Helper/releases/download/v1.13.0/tch-release-1.13.0.rar)
Данный помощник позволяет комфортно работать с контрактами и взаимодействовать с другими игроками.

* Кликабельный список контрактов в правом углу экрана
* Автоматическая разгрузка товара при достижении места сдачи
* Автоматическая смена цвета ника выбранного из списка в настройках
* Улучшенная манёвренность фуры (drift)
* Сортировка контрактов от лучших к худшим в списке контрактов
* Возможность отправки координат игрока в рацию, установка метки

## Зависимости (установить перед запуском скрипта)
> **Внимание:** Для игры с лаунчера не требуется установка зависимостей ниже.
-   [SAMP 0.3.7 R1](http://files.sa-mp.com/sa-mp-0.3.7-install.exe)
-   [CLEO 4](https://cleo.li)
-   [SAMPFUNCS v5.4.1 ](https://www.blast.hk/threads/17/) (для работы возможно потребуется установка [DirectX и Visual C++ Redistributable](https://www.dropbox.com/s/sgbnapzy66umupu/sampfuncs.zip?dl=1))
-   [Moonloader v026.5](https://www.blast.hk/threads/13305/)
-   [Mimgui](https://github.com/THE-FYP/mimgui/releases/download/v1.7.0/mimgui-v1.7.0.zip) (скопировать папку '**mimgui**' (не содержимое папки) из архива в каталог '**moonloader/lib/**')
## Установка
### Для пользователей
1. [Скачать](https://github.com/SamFredrickson/Truck-Contracts-Helper/releases/download/v1.13.0/tch-release-1.13.0.rar) архив с файлами скрипта
2. Распаковать скачанный архив в папку **moonloader** в корне игры
### Для разработчиков
1. Зайти в папку **moonloader** в корне игры
2. Склонировать проект командой:
    ```sh
    git clone https://github.com/SamFredrickson/Truck-Contracts-Helper tch
    ```
3. Перенести файл **tch-main.lua** в папку **moonloader**:
    ```sh
    cp tch/tch-main.lua .
    ```

# Обновление
Обновление скрипта происходит путем ввода команды (( **/tch.update** )) и перехода по ссылкам на скачивание и на лог изменений. 

После скачивания новой версии необходимо распаковать архив в папке **moonloader** с заменой старых файлов, а в самой игре нажать комбинацию клавиш **CTRL + R**, чтобы изменения вступили в силу.

*Проверка на актульную версию происходит автоматически при входе в игру или перезагрузке скрипта (( **CTRL + R** ))*.

# Связь с разработчиком

- [GitHub](https://github.com/SamFredrickson/Truck-Contracts-Helper/issues/new)
- [BLASTHACK](https://www.blast.hk/members/519123/)