# [Помощник для работы с контрактами дальнобойщика на проекте Evolve Role Play](https://github.com/SamFredrickson/Truck-Contracts-Helper/releases/download/v1.8.1/tch-release-1.8.1.rar)
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
-   [Mimgui](https://github.com/THE-FYP/mimgui/releases/download/v1.7.0/mimgui-v1.7.0.zip) (скопировать папку '**mimgui**' (не содержимое папки) из архива в каталог '**moonloader/lib/**')
## Установка
### Для пользователей
1. [Скачать](https://github.com/SamFredrickson/Truck-Contracts-Helper/releases/download/v1.8.1/tch-release-1.8.1.rar) архив с файлами скрипта
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
Так как список контрактов формируется и сортируется на основе списка полученного из (( **/tmenu** )) для начала работы необходимо сесть в фуру и ввести команду (( **/tch.list** )), чтобы активировать список в правом нижнем углу или же дождаться пока он появится сам, если указаны соответствующие настройки в (( **/tch.menu** )).

*Чтобы активировать / деактивировать курсор мыши при открытом (( **/tch.list** )) необходимо нажать комбинацию клавиш **SHIFT + C***.

### Доступные команды
**/tch.menu** — открывает главное меню <br />
**/tch.list** — открывает список контрактов <br />
**/tch.sos [текст сообщения]** — отправляет в рацию сообщение с координатами игрока <br />
### Главное меню
Главное меню - это окно с различными вкладками, которые содержат настройки или другую интерактивную информацию.

*Чтобы получить более подробное описание каждой опции в этой вкладке необходимо навести на неё курсором мыши.*
#### Основное
В данной вкладке содержатся базовые настройки.
<p align="center">
    <img src="https://i.imgur.com/8UBdV8X.png" alt="Главное меню (основное)">
</p>

#### Контракты
В данной вкладке содержится таблица, которая нужна, чтобы задавать порядок сортировки в списке контрактов (( **/tch.list** )).

**Место** — содержит точку выдачи товара и точку сдачи <br />
**Топ** — содержит информацию о том является ли контракт топовым или нет <br />
**Сорт** — содержит число от которого зависит порядок отображения. Чем ниже - тем выше в списке и наооборот <br />
**Опции** — содержит кнопки управления, которые позволяют перемещать контракты или задать метку "TOP".

*Метка **TOP** ставится тем контрактам, которые должны визуально выделятся в списке контрактов, чтобы было очевидно, что контракт самый выгодный. Например **Нефтезавод №2 -> Порт СФ***.

<p align="center">
    <img src="https://i.imgur.com/rp0IHSZ.png" alt="Главное меню (контракты)">
</p>

#### Взаимодействие с игроками
В данной вкладке содержится таблица с ником, сообщением и координатами, полученными из рации (( **/j** )). При нажатии на кнопку **Мет.** ставится маркер на карте, благодаря которому вы сможете найти другого игрока для того, чтобы помочь ему.

<p align="center">
    <img src="https://i.imgur.com/SWlyh2h.png" alt="Главное меню (взаимодействие с игроками)">
</p>

## Контракты
В данном окне расположен список контрактов (( **/tch.list** )), который как правило появляется в правом нижнем углу экрана. Список обновляется раз в **три секунды**, если игрок находится в фуре и ещё не имеет **активный** контракт.

По стандарту открытый список не позволяет игроку взаимодействовать с ним, чтобы не блокировать мышь и поворот экрана. Для входа / выхода в режим взаимодействия со списком необходимо нажать комбинацию клавиш **SHIFT + C**.

<p align="center">
    <img src="https://i.imgur.com/eSfqHGP.png" alt="Контракты">
</p>

### Кнопки

**Взять контракт** — активирует контракт из списка контрактов (( **/tmenu** )) <br />
**Взять контракт и загрузить** — активирует контракт из списка контрактов (( **/tmenu** )), а также берёт груз (( **/tload** )) <br />
**Загрузить** — берёт груз командой (( **/tload** )). Полезно, если контракт активен, а груз не взят <br />
**Отм** — отменяет активный контракт и спавнит груз <br />

## Статистика
В данном окне выведены в ряд следующие данные:

- Текущий / предыдущий рейс
- Время в текущем / предыдущем рейсе
- Время через которое будет доступен нелегальный груз
- Опыт за сессию
- Рейсов за сессию
- Зарабаток за сессию
- Заработок за всё время

<p align="center">
    <img src="https://i.imgur.com/YqlGnYJ.png" alt="Статистика">
</p>

Статистика открывается во время нахождения игрока в фуре, если не снята галочка **Статистика заработка** в главном меню, иначе же открыть статистику можно в любое по команде **(( /tch.info ))**

# Обновление
Обновление скрипта происходит путем ввода команды (( **/tch.update** )) и перехода по ссылкам на скачивание и на лог изменений. 

После скачивания новой версии необходимо распаковать архив в папке **moonloader** с заменой старых файлов, а в самой игре нажать комбинацию клавиш **CTRL + R**, чтобы изменения вступили в силу.

*Проверка на актульную версию происходит автоматически при входе в игру или перезагрузке скрипта (( **CTRL + R** ))*.

# Связь с разработчиком

- [GitHub](https://github.com/SamFredrickson/Truck-Contracts-Helper/issues/new)
- [BLASTHACK](https://www.blast.hk/members/519123/)