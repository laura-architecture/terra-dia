if (arg[1] == 'default') then
	port = '10002'
	host = '192.168.2.202'
	nodeid = 20
else
	if (arg[1] == nil) then
		print('  [ERROR] missing parameter \'port\'')
		print('  usage: lua main.lua <port> <ip address> <nodeId>')
		os.exit()
	end;

	if(arg[2] == nil) then
		print('  [ERROR] missing parameter \'id address\'')
		print('  usage: lua main.lua <port> <ip address> <nodeId>')
		os.exit()
	end;

	if(arg[3] == nil) then
		print('  [ERROR] missing parameter \'nodeId\'')
		print('  usage: lua main.lua <port> <ip address> <nodeId>')
		os.exit()
	end;

	port = arg[1]
	host = arg[2]
	nodeid = tonumber(arg[3])
end;

arqVMX = "LauraTest01.vmx"

print('sending code to config: ' .. port .. ' ' .. host .. ' ' .. nodeid)

local tossam = require("tossam")

FileMonitor = require "FileMonitor"
ProgBin = require "ProgBin"
conf = require "conf"

-- config vars
s_sourceDir =   conf.s_sourceDir; -- 'files_vmx'
s_posfix =      conf.s_posfix -- '.vmx'
s_backupDir =   conf.s_backupDir --'backup'
n_sleepTimeS =  conf.n_sleepTimeS;--3;
exit =          conf.exit -- false

local version_file = io.open("versionID.lua", "r")

vID = tonumber( version_file:read('*l')) ;

print ('file vID ' .. vID);

version_file:close()

enviou = false;
exit = false;

while not(exit) do

    while not(mote) do

        print ('Tentando conectar');
        mote = tossam.connect
        {
					protocol = "sf",
	        host     = "192.168.2.128",
	        port     = port,
	        nodeid   = nodeid
        }
        if mote then

            -- register tossam tables
            mote:register [[
            nx_struct msg_serial [145] {
                nx_uint8_t id;
                nx_uint16_t source;
                nx_uint16_t target;
                nx_uint8_t  d8[4];
                nx_uint16_t d16[4];
                nx_uint32_t d32[2];
            };
            ]]



            mote:register [[
            nx_struct msg_serial [160] {
                nx_uint16_t versionId;
                nx_uint16_t blockLen;
                nx_uint16_t blockStart;
                nx_uint16_t startProg;
                nx_uint16_t endProg;
                nx_uint16_t nTracks;
                nx_uint16_t wClocks;
                nx_uint16_t asyncs;
                nx_uint16_t wClock0;
                nx_uint16_t gate0;
                nx_uint16_t inEvts;
                nx_uint16_t async0;
            } ;
            ]]

            mote:register [[
            nx_struct msg_serial [162] {
                nx_uint8_t reqOper;
                nx_uint16_t versionId;
                nx_uint16_t blockId;
            };
            ]]


            mote:register [[
            nx_struct msg_serial [161] {
                nx_uint16_t versionId;
                nx_uint16_t blockId;
                nx_uint8_t data[24];
            };
            ]]

            print ('conexao bem sucedida');

            os.execute("sleep " .. tonumber(n_sleepTimeS))
        else
            print ('conexão falhou, tentando novamente em ' .. n_sleepTimeS .. ' segundos')

            os.execute("sleep " .. tonumber(n_sleepTimeS))
        end
    end

    local f = io.open(arqVMX,'r')

    s_vmx = f:read("*a");

    if s_vmx ~= nil then

        enviou = false;

        ProgBin:le_arquivo(s_vmx);

        vID = vID + 1;

        -- all properties must be strings
        msg_newProVer = {
        versionId = vID,
        blockLen = ProgBin.numBlocks,
        blockStart = ProgBin.blockStart,
        startProg = ProgBin.startProg,
        endProg = ProgBin.endProg,
        nTracks = ProgBin.nTracks,
        wClocks = ProgBin.wClocks,
        asyncs = ProgBin.asyncs,
        wClock0 = ProgBin.wClock0,
        gate0 = ProgBin.gate0,
        inEvts = ProgBin.inEvts,
        async0 = ProgBin.async0
    }
    mote:send(msg_newProVer,160);
else
    print('no string in file ' .. os.date());
end

print('sent 160: ')

for k, v in pairs( msg_newProVer ) do
    print(k, v)
end

while (mote) do

    local stat, msg, emsg = pcall(function() return mote:receive() end)
    if stat then
        print("")
        print("")
        if msg then
            print("  [ message received ]")
            for k, v in pairs( msg ) do
                print(k, v)
            end
            print("----------------------------------")

            if msg[1] == 162 then
                --checar versionId antes de começar a enviar
                if msg.versionId >= vID then
                    -- version_file = io.open("versionID.lua", "w")
                    -- version_file:write(msg.versionID .. '')
                    -- version_file:close()

                    -- vID = msg.versionID + 1;
                end

                --carrega com progbin
                msg_blk = {
                  versionId = vID;
                  blockId = msg.blockId;
                  data = ProgBin.ProgData[msg.blockId + 1];
            }

            mote:send(msg_blk,161)--envia o bloco
            print("     message type: " .. msg[1]) ;
                print('     block ' .. msg.blockId .. ' sent ' );
            else
                print("     message type: " .. msg[1]) ;
                end

                if msg[1] == 161 then
                    if (msg.blockId + 1) == ProgBin.lastBlock then
                        --ultima mensagem recebida
                        print("     received final message! code from " .. vID .. " is running " ) ;

                        version_file = io.open("versionID.lua", "w")
                        version_file:write(vID .. '')

                        version_file:close()

                        enviou = true;

                        break;
                    end

                end


            else
                if emsg == "closed" then
                    --caso entre aqui não é para desconectar, é para tentar conectar novamente até conseguir
                    print("connection closed")
                    mote:unregister()
                    mote:close()
                    mote = nil;
                    --exit = true --reconnect = true
                    break
                end
            end
        else
            --caso entre aqui não é para desconectar, é para tentar conectar novamente até conseguir
            print("receive() got an error:"..msg)
            mote:unregister()
            mote:close()
            mote = nil;
            --exit = true --reconnect = true
            break
        end
    end

    --fim do envio, após carregar, o arquivo eh enviado para uma outra pasta de backup
    if enviou then
        exit = true;
    end

end
