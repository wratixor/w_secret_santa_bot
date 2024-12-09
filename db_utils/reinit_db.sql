DROP SCHEMA IF EXISTS sesa CASCADE;
CREATE SCHEMA sesa AUTHORIZATION rmaster;

drop table if exists sesa.ss_user cascade;
CREATE TABLE sesa.ss_user (
    user_id bigint NOT NULL,
    first_name varchar(64) not null,
    last_name varchar(64) null,
    username varchar(64) null,
    enable_pm boolean not null default false,
	CONSTRAINT "ss_user$pk" PRIMARY KEY (user_id)
);

drop table if exists sesa.ss_chat cascade;
CREATE TABLE sesa.ss_chat (
    chat_id bigint NOT NULL,
    chat_type varchar(64) not null,
    chat_title varchar(64) null,
	CONSTRAINT "ss_chat$pk" PRIMARY KEY (chat_id)
);

drop table if exists sesa.ss_user_chat cascade;
CREATE TABLE sesa.ss_user_chat (
    user_id bigint references sesa.ss_user(user_id),
    chat_id bigint references sesa.ss_chat(chat_id),
	CONSTRAINT "ss_user_chat$pk" PRIMARY KEY (chat_id, user_id)
);

drop table if exists sesa.ss_present cascade;
CREATE TABLE sesa.ss_present (
    user_from_id bigint references sesa.ss_user(user_id),
    user_to_id bigint references sesa.ss_user(user_id),
    chat_id bigint references sesa.ss_chat(chat_id),
	CONSTRAINT "ss_present$pk" PRIMARY KEY (chat_id, user_from_id, user_to_id)
);


DROP FUNCTION IF EXISTS sesa.s_aou_user(int8, text, text, text);
CREATE OR REPLACE FUNCTION sesa.s_aou_user(i_user_id bigint, i_first_name text, i_last_name text, i_username text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_add_user boolean := false;
  l_update_user boolean := false;
  l_check_hash boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_first_name text := coalesce(i_first_name, '');
  l_last_name text := coalesce(i_last_name, '');
  l_username text := coalesce(i_username, '');

  l_hash text := l_first_name||l_last_name||l_username;

 BEGIN
  l_check_user := ((select count(1) from sesa.ss_user as u where u.user_id = l_user_id) = 1);
  IF not l_check_user THEN
    insert into sesa.ss_user (user_id, first_name, last_name, username)
                       values (l_user_id, l_first_name, l_last_name, l_username);
    l_add_user := true;
  ELSE
    l_check_hash := ((select first_name||last_name||username as hash from sesa.ss_user as u where u.user_id = l_user_id) = l_hash);
    IF not l_check_hash THEN
      update sesa.ss_user set first_name = l_first_name, last_name = l_last_name, username = l_username where user_id = l_user_id;
      l_update_user := true;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when l_update_user then 'Успешно обновлено'
           when l_add_user then 'Пользователь добавлен'
           when l_check_user and l_check_hash then 'Обновление не требуется'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;

DROP FUNCTION IF EXISTS sesa.s_enable_pm(int8);
CREATE OR REPLACE FUNCTION sesa.s_enable_pm(i_user_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_update_user boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);

 BEGIN
  l_check_user := ((select count(1) from sesa.ss_user as u where u.user_id = l_user_id) = 1);
  IF l_check_user THEN
    update sesa.ss_user set enable_pm = true where user_id = l_user_id;
    l_update_user := true;
  END IF;

  RETURN (
    SELECT
      case when    l_update_user then 'Успешно обновлено'
           when not l_check_user then 'Пользователь не найден'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;

DROP FUNCTION IF EXISTS sesa.s_aou_chat(int8, text, text);
CREATE OR REPLACE FUNCTION sesa.s_aou_chat(i_chat_id bigint, i_chat_type text, i_chat_title text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_chat boolean := false;
  l_add_chat boolean := false;
  l_update_chat boolean := false;
  l_check_hash boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_chat_type text := coalesce(i_chat_type, '');
  l_chat_title text := coalesce(i_chat_title, '');

  l_hash text := l_chat_type||l_chat_title;

 BEGIN
  l_check_chat := ((select count(1) from sesa.ss_chat as c where c.chat_id = l_chat_id) = 1);
  IF not l_check_chat THEN
    insert into sesa.ss_chat (chat_id, chat_type, chat_title)
                       values (l_chat_id, l_chat_type, l_chat_title);
    l_add_chat := true;
  ELSE
    l_check_hash := ((select chat_type||chat_title as hash from sesa.ss_chat as c where c.chat_id = l_chat_id) = l_hash);
    IF not l_check_hash THEN
      update sesa.ss_chat set chat_type = l_chat_type, chat_title = l_chat_title, update_date = now() where chat_id = l_chat_id;
      l_update_chat := true;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when l_update_chat then 'Успешно обновлено'
           when l_add_chat then 'Группа добавлена'
           when l_check_chat and l_check_hash then 'Обновление не требуется'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;

DROP FUNCTION IF EXISTS sesa.s_join(int8, int8);
CREATE OR REPLACE FUNCTION sesa.s_join(i_user_id bigint, i_chat_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;
  l_check_query boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);

 BEGIN
  l_check_user  := ((select count(1) from sesa.ss_user      as u  where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from sesa.ss_chat      as c  where c.chat_id = l_chat_id) = 1);
  l_check_isset := ((select count(1) from sesa.ss_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    IF not l_check_isset THEN
      insert into sesa.ss_user_chat (user_id, chat_id) values (l_user_id, l_chat_id);
      l_check_query := true;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when     l_check_query then 'Успешно присоединился к группе'
           when     l_check_isset then 'Уже есть в группе'
           when not  l_check_user then 'Неизвестный пользователь'
           when not  l_check_chat then 'Неизвестная группа'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP FUNCTION IF EXISTS sesa.s_leave(int8, int8);
CREATE OR REPLACE FUNCTION sesa.s_leave(i_user_id bigint, i_chat_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;
  l_check_query boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);

 BEGIN
  l_check_user  := ((select count(1) from sesa.ss_user      as u  where u.user_id = l_user_id) = 1);
  l_check_chat  := ((select count(1) from sesa.ss_chat      as c  where c.chat_id = l_chat_id) = 1);
  l_check_isset := ((select count(1) from sesa.ss_user_chat as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id) = 1);

  IF l_check_user and l_check_chat THEN
    IF l_check_isset THEN
      delete from sesa.ss_user_chat where user_id = l_user_id and chat_id = l_chat_id;
      l_check_query := true;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when     l_check_query then 'Успешно вышел из группы'
           when not l_check_isset then 'Уже нет в группе'
           when not  l_check_user then 'Неизвестный пользователь'
           when not  l_check_chat then 'Неизвестная группа'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;

DROP FUNCTION IF EXISTS sesa.s_generate_present(int8);
CREATE OR REPLACE FUNCTION sesa.s_generate_present(i_chat_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_query boolean := false;
  l_check_isset boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_count int := coalesce((select count(*) from sesa.ss_user_chat as c where c.chat_id = l_chat_id), 0);

 BEGIN

  IF l_user_count > 0 THEN
    l_check_isset := ((select count(1) from sesa.ss_present as cc where cc.chat_id = l_chat_id) > 0);
    IF l_check_isset THEN
      delete from sesa.ss_present where chat_id = l_chat_id;
    END IF;
    IF l_user_count < 6 THEN
      with u_all as (
        select uc.user_id
             , row_number() over(order by random()) as rnl
          from sesa.ss_user_chat as uc
         where uc.chat_id = l_chat_id
      )
      , c_0 as (
        select user_id
             , rnl
             , max_i
             , min_i
          from u_all
          join (select max(rnl) as max_i
                     , min(rnl) as min_i
                  from u_all
               ) as agr on true
      )
      , j_0 as (
        select user_id
             , case when rnl = max_i then min_i
                    else rnl + 1 end as needrnl
             , rnl
          from c_0
      )
      , toinsert as (
        select u1.user_id as user_from_id
             , u2.user_id as user_to_id
          from j_0 as u1
          join j_0 as u2 on u2.rnl = u1.needrnl
      )
      insert into sesa.ss_present (user_from_id, user_to_id, chat_id) select user_from_id, user_to_id, l_chat_id::bigint from toinsert;
      l_check_query := true;
    ELSE
      with u_all as (
        select uc.user_id
             , row_number() over(order by random()) as rn
          from sesa.ss_user_chat as uc
         where uc.chat_id = l_chat_id
      )
      , loop_0 as (
        select u.user_id
             , row_number() over(order by random()) as rnl
          from u_all as u
         where u.rn % 2 = 0
      )
      , loop_1 as (
        select u.user_id
             , row_number() over(order by random()) as rnl
          from u_all as u
         where u.rn % 2 = 1
      )
      , c_0 as (
        select user_id
             , rnl
             , max_i
             , min_i
          from loop_0
          join (select max(rnl) as max_i
                     , min(rnl) as min_i
                  from loop_0
               ) as agr on true
      )
      , c_1 as (
        select user_id
             , rnl
             , max_i
             , min_i
          from loop_1
          join (select max(rnl) as max_i
                     , min(rnl) as min_i
                  from loop_1
               ) as agr on true
      )
      , j_0 as (
        select user_id
             , case when rnl = max_i then min_i
                    else rnl + 1 end as needrnl
             , rnl
          from c_0
      )
      , j_1 as (
        select user_id
             , case when rnl = max_i then min_i
                    else rnl + 1 end as needrnl
             , rnl
          from c_1
      )
      , s_0 as (
        select u1.user_id as user_from_id
             , u2.user_id as user_to_id
          from j_0 as u1
          join j_0 as u2 on u2.rnl = u1.needrnl
      )
      , s_1 as (
        select u1.user_id as user_from_id
             , u2.user_id as user_to_id
          from j_1 as u1
          join j_1 as u2 on u2.rnl = u1.needrnl
      )
      , toinsert as (
        select user_from_id, user_to_id from s_0 union
        select user_from_id, user_to_id from s_1
      )
      insert into sesa.ss_present (user_from_id, user_to_id, chat_id) select user_from_id, user_to_id, l_chat_id::bigint from toinsert;
      l_check_query := true;
    END IF;
  END IF;
  RETURN (
    SELECT
      case when l_check_query then 'Распределение выполнено'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;

DROP TYPE IF EXISTS sesa.t_status CASCADE;
CREATE TYPE sesa.t_status AS (
	chat_title text,
	username text,
	enable_pm boolean);


DROP FUNCTION IF EXISTS sesa.r_status(int8);
CREATE OR REPLACE FUNCTION sesa.r_status(i_chat_id bigint)
 RETURNS SETOF sesa.t_status
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 20
AS $function$
DECLARE

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);

BEGIN
  IF l_chat_id <> 0 THEN
    RETURN QUERY
    select c.chat_title::text as chat_title
         , u.username::text as username
         , u.enable_pm::boolean as enable_pm
      from sesa.ss_user_chat as uc
      join sesa.ss_chat as c on uc.chat_id = c.chat_id
      join sesa.ss_user as u on uc.user_id = u.user_id
     where uc.chat_id = l_chat_id
     order by c.chat_title, u.username
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;

DROP TYPE IF EXISTS sesa.t_present CASCADE;
CREATE TYPE sesa.t_present AS (
	chat_title text,
	from_userid bigint,
	from_username text,
	to_first_name text,
	to_last_name text,
	to_username text);


DROP FUNCTION IF EXISTS sesa.r_present(int8);
CREATE OR REPLACE FUNCTION sesa.r_present(i_chat_id bigint)
 RETURNS SETOF sesa.t_present
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 20
AS $function$
DECLARE

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_check_isset boolean := true;

BEGIN
  l_check_isset := ((select count(1) from sesa.ss_present as cc where cc.chat_id = l_chat_id) > 0);
  IF not l_check_isset THEN
    PERFORM sesa.s_generate_present(l_chat_id);
  END IF;
  IF l_chat_id <> 0 THEN
    RETURN QUERY
    select c.chat_title::text as chat_title
         , uf.user_id::bigint as from_userid
         , uf.username::text as from_username
         , ut.first_name::text as to_first_name
         , ut.last_name::text as to_last_name
         , ut.username::text as to_username
      from sesa.ss_present as uc
      join sesa.ss_chat as c  on uc.chat_id = c.chat_id
      join sesa.ss_user as uf on uc.user_from_id = uf.user_id
      join sesa.ss_user as ut on uc.user_to_id = ut.user_id
     where uc.chat_id = l_chat_id
     order by c.chat_title, uf.user_id
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;

DROP FUNCTION IF EXISTS sesa.s_name_kick(int8, text);
CREATE OR REPLACE FUNCTION sesa.s_name_kick(i_chat_id bigint, i_username text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;
  l_check_query boolean := false;

  l_user_id bigint;
  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_username text := coalesce(i_username, '');

 BEGIN
  l_user_id := (select user_id from sesa.ss_user as u where u.username = l_username limit 1);
  l_check_chat := ((select count(1) from sesa.ss_chat as c where c.chat_id = l_chat_id) = 1);
  l_check_user := (l_user_id is not null);

  IF l_check_user and l_check_chat THEN
      delete from sesa.ss_user_chat where user_id = l_user_id and chat_id = l_chat_id;
      l_check_query := true;
  END IF;

  RETURN (
    SELECT
      case when     l_check_query then l_username||' исключён из группы.'
           when not  l_check_user then 'Неизвестный пользователь'
           when not  l_check_chat then 'Неизвестная группа'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;