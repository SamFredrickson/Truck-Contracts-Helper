# Помощник для работы с контрактами дальнобойщика на проекте Evolve Role Play
Данный помощник позволяет комфортно работать с контрактами и взаимодействовать с другими игроками.

* Кликабельный список контрактов в правом углу экрана
* Автоматическая разгрузка товара при достижении места сдачи
* Автоматическая смена цвета ника выбранного из списка в настройках
* Улучшенная манёвренность фуры (drift)
* Сортировка контрактов от лучших к худшим в списке контрактов
* Возможность отправки координат игрока в рацию, установка метки
## Зависимости (установить перед запуском скрипта)
-   [SAMP 0.3.7 R1](http://files.sa-mp.com/sa-mp-0.3.7-install.exe)
-   [CLEO 4](https://cleo.li)
-   [SAMPFUNCS v5.4.1 ](https://www.blast.hk/threads/17/) (для работы возможно потребуется установка [DirectX и Visual C++ Redistributable](https://www.dropbox.com/s/sgbnapzy66umupu/sampfuncs.zip?dl=1))
-   [Moonloader v026.5](https://www.blast.hk/threads/13305/)
## Установка
### Для пользователей
1. Скачать архив с файлами скрипта
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
## Использование
Так как список контрактов формируется и сортируется на основе списка полученного из **/tmenu** для начала работы необходимо сесть в фуру и ввести команду **/tch.list**, чтобы активировать список в правом нижнем углу или же дождаться пока он появится сам, если указаны соответствующие настройки в **/tch.menu**.
### Доступные команды
**/tch.menu** — открывает главное меню <br />
**/tch.list** — открывает список контрактов <br />
**/tch.coords.send [текст сообщения]** — отправляет в рацию сообщение с координатами игрока <br />
### Главное меню
Главное меню - это окно с различными вкладками, которые содержат настройки или другую интерактивную информацию.

*Чтобы получить более подробное описание каждой опции в этой вкладке необходимо навести на неё курсором мыши.*
#### Основное
<p align="center">
    <img src="https://i.imgur.com/RAYU0kA.png" alt="Главное меню (основное)">
</p>

#### Контракты
В данной вкладке содержится таблица, которая нужна, чтобы задавать порядок сортировки в списке контрактов (( **/tch.list** )).

**Место** — содержмит точку выдачи товара и точку сдачи <br />
**Топ** — содержит информацию о том является ли контракт топовым или нет <br />
**Сорт** — содержит число от которого зависит порядок отображения. Чем ниже - тем выше в списке и наооборот <br />
**Опции** — содержит кнопки управления, которые позволяют перемещать контракты или задать метку "TOP".

*Метка **TOP** ставится тем контрактам, которые должен визуально выделятся в списке контрактов, чтобы было очевидно, что контракт самый крутой. Например **Нефтезавод №2 -> Порт СФ***.

<p align="center">
    <img src="https://i.imgur.com/puncrDP.png" alt="Главное меню (контракты)">
</p>