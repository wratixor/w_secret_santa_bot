import logging

import asyncpg
from aiogram import Router
from aiogram.filters import CommandStart, Command, CommandObject
from aiogram.types import Message
from asyncpg import Record

from create_bot import bot_url, bot
from middlewares.db_middleware import DatabaseMiddleware
from middlewares.qparam_middleware import QParamMiddleware
import db_utils.db_request as r

start_router = Router()
start_router.message.middleware(DatabaseMiddleware())
start_router.message.middleware(QParamMiddleware())
logger = logging.getLogger(__name__)


@start_router.message(CommandStart())
async def cmd_start(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        await message.answer(f'Доброго времени суток всем в этом чатике!'
                             f'\nПолный список команд с описаниями доступен по команде /help'
                             f'\nДля присоединения к группе введите команду /join'
                             f'\nили откройте бот по ссылке {bot_url}?start={message.chat.id}'
                             f'\n<i>Не забудьте активировать бот в ЛС, чтобы он мог Вам написать!</i>')
    else:
        await r.s_enable_pm(db, message.from_user.id)
        command_args: str = command.args
        if command_args:
            res: str = await r.s_join(db, message.from_user.id, int(command_args))
            await message.answer(f'Привет, {quname}!'
                                 f'\nПолный список команд с описаниями доступен по команде /help'
                                 f'\nПрисоединение к группе: {res}')
        else:
            await message.answer(f'Привет, {quname}!'
                                 f'\nПолный список команд с описаниями доступен по команде /help'
                                 f'\nДля присоединения к группе добавьте бота в группу'
                                 f', активируйте (/start) и введите команду /join')

@start_router.message(Command('test'))
async def test(message: Message, command: CommandObject, quname: str, isgroup: bool):
    command_args: str = command.args
    text: str = (f'test: {command_args}'
                 f'\nquname: {quname}'
                 f'\nisgroup: {isgroup}')
    await message.reply(text)
    logger.info(command_args)

@start_router.message(Command('developer_info'))
async def developer_info(message: Message):
    text: str = (f'Developer: @wratixor @tanatovich'
                 f'\nSite: https://wratixor.ru'
                 f'\nProject: https://wratixor.ru/projects/w_secret_santa_bot'
                 f'\nDonations: https://yoomoney.ru/to/4100118849397169'
                 f'\nGithub: https://github.com/wratixor/w_secret_santa_bot')
    await message.answer(text)

@start_router.message(Command('help'))
async def helper(message: Message):
    answer: str = (f'Доброго времени суток!'
                   f'\n/start - Активация бота в группе или ЛС'
                   f'\n/help - Справка по командам'
                   f'\n/status - Статус участников группы'
                   f'\n/join - Присоединиться к ТС'
                   f'\n/leave - Покинуть ТС'
                   f'\n/kick - Выкинуть из ТС'
                   f'\n<i>Пример: /kick @username</i>'
                   f'\n/mix - Перемешать подарки'
                   f'\n/send - Разослать адресатов в ЛС'
                   f'\n<i>Не забудьте активировать бот в ЛС, чтобы он мог Вам написать!</i>')
    await message.answer(answer)

@start_router.message(Command('join'))
async def join(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    res: str
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        res = await r.s_join(db, message.from_user.id, message.chat.id)
        await message.answer(f'{res}')
    else:
        await message.answer('Команда доступна только в группе!')

@start_router.message(Command('leave'))
async def leave(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    res: str
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        res = await r.s_leave(db, message.from_user.id, message.chat.id)
        await message.answer(f'{res}')
    else:
        await message.answer('Команда доступна только в группе!')

@start_router.message(Command('kick'))
async def kick(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    res: str
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isgroup:
        await r.s_aou_chat(db, message.chat.id, message.chat.type, message.chat.title)
        username: str = command.args
        if username:
            res = await r.s_name_kick(db, message.chat.id, username)
        else:
            res = 'Должно быть: /kick @username'
        await message.answer(f'{res}')
    else:
        await message.answer('Команда доступна только в группе!')

@start_router.message(Command('status'))
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    res: list[Record]
    answer: str = f'Могу отправить сообщения:\n'
    if isgroup:
        res = await r.r_status(db, message.chat.id)
        for row in res:
            answer += ('✔' if row['enable_pm'] else '❌')
            answer += f": {row['username']}\n"
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(Command('mix'))
async def mix(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    res: list[Record]
    answer: str
    if isgroup:
        answer = await r.s_generate_present(db, message.chat.id)
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)

@start_router.message(Command('send'))
async def send(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    res: list[Record]
    answer: str
    if isgroup:
        res = await r.r_present(db, message.chat.id)
        for row in res:
            try:
                await bot.send_message(row['from_userid']
                                       , f'Приветствую, {row['from_username']}!'
                                         f'\nВ чате "{row['chat_title']}" Вам выпала честь одарить подарком:'
                                         f'\n{row['to_first_name']} {row['to_last_name']} - {row['to_username']}')
            except Exception as e:
                logger.error(f'send(): {e}')
        answer = 'Рассылка отправлена'
    else:
        answer = 'Команда доступна только в группе!'
    await message.answer(answer)