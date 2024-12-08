PROJECT = "X-RAY"
VERSION = "1.0.0"

Filament_GPIO = 8
Filament_Frequency = 50000
Filament_Precision = 1000
TEMP_I2C_ID = 0
TEMP_I2C_SPEED = i2c.FAST
SSID = 'X-RAY'
IP = '192.168.4.1'
PORT = 80
NETMASK = '255.255.255.0'
GATEWAY = '192.168.4.1'

sys = require("sys")
-- aht10 = require "aht10"
MOD_TYPE = rtos.bsp()
BUZZER = gpio.setup(19, 0)
KV = gpio.setup(2, 0)
LEDA = gpio.setup(13, 0)
LEDB = gpio.setup(12, 0)
i2c.setup(TEMP_I2C_ID, TEMP_I2C_SPEED)
log.setLevel("INFO")

log.info('X-RAY CONTROLLER')
log.info('TCLAB ID:TCP-02')
log.info('Created By Yang Haotian')

function Filament(percent)
    pwm.open(Filament_GPIO, Filament_Frequency, math.floor(percent * Filament_Precision / 100), 0, Filament_Precision)
end

function GetTemp()
    aht10_data = aht10.get_data()
    return aht10_data.T
end

sys.taskInit(function()
    -- aht10.init(TEMP_I2C_ID)
    LEDA(1)
    -- 开启热点
    log.info("开启WIFI热点...")
    wlan.init()
    sys.wait(300)
    wlan.createAP(SSID)
    log.info("WIFI热点已开启,SSID:" .. SSID)

    Filament(100)

    log.info('灯丝:100%')

    -- 启动服务器
    httpsrv.start(PORT, function(client, method, uri, headers, body)
        if uri == "/test" then
            coroutine.resume(coroutine.create(function()
                BUZZER(1)
                KV(1)
                sys.wait(1000)
                KV(0)
                BUZZER(0)
            end))
            return 200, {}, "ok"
        elseif uri == "/longtest" then
            coroutine.resume(coroutine.create(function()
                BUZZER(1)
                KV(1)
                sys.wait(10000)
                KV(0)
                BUZZER(0)
            end))
            return 200, {}, "ok"
        elseif uri == "/led/1/on" then
            LEDA(1)
            return 200, {}, "ok"
        elseif uri == "/led/1/off" then
            LEDA(0)
            return 200, {}, "ok"
        elseif uri == "/led/2/on" then
            LEDB(1)
            return 200, {}, "ok"
        elseif uri == "/led/2/off" then
            LEDB(0)
            return 200, {}, "ok"
        end
        -- 返回值的约定 code, headers, body
        -- 若没有返回值, 则默认 404, {} ,""
        return 404, {}, "Not Found" .. uri
    end)
    log.info('服务器已启动.')

end)

sys.run()
