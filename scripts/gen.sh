#!/bin/bash
QUARTUS_PATH=/opt/altera/17.1/quartus/bin/
FLASH_DEVICE=EPCQ128A
SOF_OPT_FILE=create_sof.sof
SOF_PATH=../output_files/
SOF_FILE=WIB.sof
HEX_PATH=../output_files/
POF_FILE=./temp.pof

TYPE=FELIX
FW_VER=18100901


#create a named sof file
cp ${SOF_PATH}/WIB.sof ${SOF_PATH}/protoDUNEWIB_${TYPE}_${FW_VER}.sof

#create options file for altera
echo "BITSTREAM_COMPRESSION=ON" >  ${SOF_OPT_FILE}
echo "AUTO_CREATE_RPD=OFF"      >> ${SOF_OPT_FILE}
${QUARTUS_PATH}/quartus_cpf --convert --option=${SOF_OPT_FILE} --device=${FLASH_DEVICE} ${SOF_PATH}/${SOF_FILE} ${POF_FILE}
rm ${SOF_OPT_FILE}

#Create intel hex file from POF file
${QUARTUS_PATH}/quartus_cpf --convert ${POF_FILE} ${HEX_PATH}/protoDUNEWIB_${TYPE}_${FW_VER}.hexout
rm ${POF_FILE}
