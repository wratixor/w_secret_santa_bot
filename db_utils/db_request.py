import datetime
import logging
import asyncpg
from asyncpg import Record

logger = logging.getLogger(__name__)

async def s_join(pool: asyncpg.pool.Pool, user_id: int, group_id: int) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from sesa.s_join($1::bigint, $2::bigint)"
                                         , user_id, group_id)
        except Exception as e:
            result = f"Exception s_name_join({user_id}, {group_id}): {e}"
            logger.error(result)
    return result

async def s_leave(pool: asyncpg.pool.Pool, user_id: int, group_id: int) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from sesa.s_leave($1::bigint, $2::bigint)"
                                         , user_id, group_id)
        except Exception as e:
            result = f"Exception s_name_leave({user_id}, {group_id}): {e}"
            logger.error(result)
    return result

async def s_name_kick(pool: asyncpg.pool.Pool, group_id: int, username: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from sesa.s_name_kick($1::bigint, $2::text)"
                                         , group_id, username)
        except Exception as e:
            result = f"Exception s_name_kick({group_id}, {username}): {e}"
            logger.error(result)
    return result

async def s_aou_user(pool: asyncpg.pool.Pool, user_id: int, first_name: str, last_name: str, username: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from sesa.s_aou_user($1::bigint, $2::text, $3::text, $4::text)"
                                         , user_id, first_name, last_name, username)
        except Exception as e:
            result = f"Exception s_aou_user({user_id}, {first_name}, {last_name}, {username}): {e}"
            logger.error(result)
    return result

async def s_enable_pm(pool: asyncpg.pool.Pool, user_id: int) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from sesa.s_enable_pm($1::bigint)", user_id)
        except Exception as e:
            result = f"Exception s_enable_pm({user_id}): {e}"
            logger.error(result)
    return result

async def s_aou_chat(pool: asyncpg.pool.Pool, group_id: int, group_type: str, group_title: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from sesa.s_aou_chat($1::bigint, $2::text, $3::text)"
                                         , group_id, group_type, group_title)
        except Exception as e:
            result = f"Exception s_aou_chat({group_id}, {group_type}, {group_title}): {e}"
            logger.error(result)
    return result

async def s_generate_present(pool: asyncpg.pool.Pool, group_id: int) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from sesa.s_generate_present($1::bigint)", group_id)
        except Exception as e:
            result = f"Exception s_generate_present({group_id}): {e}"
            logger.error(result)
    return result

async def r_status(pool: asyncpg.pool.Pool, group_id: int = None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from sesa.r_status($1::bigint)", group_id)
        except Exception as e:
            logger.error(f"Exception r_status({group_id}): {e}")
    return result

async def r_present(pool: asyncpg.pool.Pool, group_id: int = None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from sesa.r_present($1::bigint)", group_id)
        except Exception as e:
            logger.error(f"Exception r_present({group_id}): {e}")
    return result