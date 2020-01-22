
/******************************************************************************
 *                                                                            *
 *           Calculates a CRC-20 over the data at Din, data may               *
 *           already arrive when Reset is high                                *
 *                                                                            *
 *           Frans Schreuder (Nikhef) franss@nikhef.nl                        *
 *                                                                            *
 *****************************************************************************/


#define     CRC_Width 20
#define     Poly 0xc1acf
#define     InitVal 0xfffff

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

uint32_t ToIndirectInitVal(uint32_t Direct)
{
    uint32_t InDirect;
    for (int k=0; k<=CRC_Width; k++)
    {
        if(k == 0)
        {
            InDirect = Direct;
        }
        else
        {
            if((InDirect&1)==1)
            {
                InDirect = (InDirect>>1) ^ ((1<<(CRC_Width-1))|(Poly>>1));
            }
            else
            {
                InDirect = InDirect>>1;
            }
        }
    }
    return InDirect; 
}


uint32_t CRC(const uint32_t* data, int length)
{
    uint32_t Reg;
    uint32_t ApplyPoly;
    uint32_t ones = (1<<CRC_Width)-1;
    //Reset sequence, initialize
    Reg = ToIndirectInitVal(InitVal);
    for(int i=0; i<length; i++)
    {
        for(int k = 1; k<=32; k++)
        {
            if (Reg&(1<<(CRC_Width-1)))
            {
                Reg = ((Reg<<1)|((data[i]>>(32-k))&1)) ^ Poly;
            }
            else
            {
                Reg = ((Reg<<1) | ((data[i]>>(32-k))&1));
            }
        }
        Reg &= ones;
    }
    //we need one more loop to output the CRC register to the output.
    for(int k = 0; k<CRC_Width; k++)
    {
        if (Reg&(1<<(CRC_Width-1)))
        {
            Reg = ((Reg<<1)) ^ Poly;
        }
        else
        {
            Reg = ((Reg<<1) );
        }
    }
    Reg &= ones;
    return Reg;
}

int main(int argc, char** argv)
{
    int length=argc-1;
    
    if(length<1)
    {
        fprintf(stderr, "Usage:\n  crc <32 bit hex value> <32 bit hex value> <32 bit hex value> ...\n");
    }
    
    uint32_t *data = malloc(length*4);
    for(int i=0; i<length; i++)
    {
        sscanf(argv[i+1],"%X", &(data[i]));
    }
    uint32_t crc = CRC(data, length);
    printf("%05X\n", crc);
        
    return 0;
}




