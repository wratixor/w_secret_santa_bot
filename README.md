<H1>w Secret Santa Bot</H1>
<h2>wSSB - a simple bot for secret santa.</h2>
<h2>Site: https://wratixor.ru/projects/w_secret_santa_bot</h2>
<h2>TG: https://t.me/w_secret_santa_bot</h2>

<h3>Requirements:</h3>
 - aiogram<br>
 - python-decouple<br>
 - asyncpg<br>

<h3>Install:</h3>
- <code>git clone https://github.com/wratixor/w_secret_santa_bot</code><br>
- <code>python3 -m venv .venv</code><br>
- <code>source .venv/bin/activate</code><br>
- <code>pip install -r requirements.txt</code><br>
- Edit template.env and rename to .env<br>
- Run <code>db_utils/reinit_db.sql</code> into PostgreSQL CLI<br>\
- Edit ssbot.service<br>
- <code>ln -s /../bot.service /etc/systemd/system</code><br>
- <code>systemctl enable ssbot.service</code><br>
- <code>systemctl start ssbot.service</code><br>