lfs = require ("lfs")

FileMonitor = {};
--[[funcao que retorna o nome dos arquivos dentro de um diretorio ]]
function FileMonitor.le_diretorio (path,extension)
  files = {};
  print(path .. ' file monitor')
    for file in lfs.dir(path) do
        
        if file ~= "." and file ~= ".." and string.sub(file,-4) == extension and string.len(file) > 4 then
            local f = io.open(path.. '/' ..file,'r')
            files[#files + 1] = f;
            
            return file , f;
        end
    end
    return nil , nil;
end


return FileMonitor;