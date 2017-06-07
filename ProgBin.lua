ProgBin = {};


ProgBin.parametros = {};
ProgBin.block       = {};
ProgBin.BLOCK_SIZE = 24;


ProgBin.MAX_BLOCKS = 500; --16;
ProgBin.MAX_TABLE_LEN = ProgBin.BLOCK_SIZE * ProgBin.MAX_BLOCKS;


ProgBin.ProgData = {};


for blk=1,ProgBin.MAX_BLOCKS do
      ProgBin.ProgData[blk] = {}     -- create a new row
      for x=1,ProgBin.BLOCK_SIZE do
        ProgBin.ProgData[blk][x] = 0
      end
    end

function reset_ProgData()
          -- create the matrix
    for blk=1,ProgBin.MAX_BLOCKS do
      ProgBin.ProgData[blk] = {}     -- create a new row
      for x=1,ProgBin.BLOCK_SIZE do
        ProgBin.ProgData[blk][x] = 0
      end
    end

    ProgBin.parametros = {};
    linha1 = nill;
end

function magiclines(s)
        if s:sub(-1)~="\n" then s=s.."\n" end
        return s:gmatch("(.-)\n")
end


function ProgBin:le_arquivo(stringVMX)
--reset_ProgData();

  --linha1 = string.gmatch(stringVMX, ".*[^\n]")
    linha1 = nill;
    reset_ProgData();

    for w in magiclines(stringVMX) do
      if(linha1 == nill) then
        linha1 = w
        for p in string.gmatch(linha1, "%d*[^ ]") do
           ProgBin.parametros[#ProgBin.parametros + 1] = p
           if ProgBin.parametros[#ProgBin.parametros ] == nill then
             return nill
           end
         end
        --41 109 3 3 0 0 24 0 24
        ProgBin.startProg = tonumber (ProgBin.parametros[1]);
        ProgBin.endProg   = tonumber (ProgBin.parametros[2]);
        ProgBin.nTracks   = tonumber (ProgBin.parametros[3]);
        ProgBin.wClocks   = tonumber (ProgBin.parametros[4]);
        ProgBin.asyncs    = tonumber (ProgBin.parametros[5]);
        ProgBin.wClock0   = tonumber (ProgBin.parametros[6]);
        ProgBin.gate0     = tonumber (ProgBin.parametros[7]);
        ProgBin.inEvts    = tonumber (ProgBin.parametros[8]);
        ProgBin.async0    = tonumber (ProgBin.parametros[9]);

        ProgBin.blockStart =  math.floor(ProgBin.startProg/ProgBin.BLOCK_SIZE);
      else
        if w == nill then
          break;
        end

        xByte = tonumber ( string.sub ( w,1,2),16 ) ;
        xAddr = ( tonumber( string.sub(w,5,10) ) );

        blockCount = 1 + math.floor(xAddr/ProgBin.BLOCK_SIZE); -- 00000 a 00109 => 1 + ( 0 a 4,5 ) => bloco: 1 a 5 - total 5 blocos
          --mode de descarte do primeiro bloco
        --blockCount =  math.floor(xAddr/ProgBin.BLOCK_SIZE);

        byteCount = 1 + (xAddr%ProgBin.BLOCK_SIZE); --1 a 24


        if blockCount > 0 then
        ProgBin.ProgData[blockCount][byteCount] = xByte;

        end;

      end
    end

    ProgBin.numBlocks = (blockCount-ProgBin.blockStart);
    ProgBin.lastBlock = blockCount;


end

function ProgBin.getBlock(blockId)

    return ProgBin.ProgData[blockId];
end



return ProgBin;
