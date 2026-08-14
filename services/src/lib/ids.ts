import { randomBytes } from "node:crypto";

const ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";


function char(index:number):string{
    const value=ALPHABET[index%ALPHABET.length]
    if(value===undefined){
        throw new Error(`Alphabet index out of range:${index}`); 
    }

    return value;
}

export function ulid(now:number=Date.now()):string{
    let time="";
    let remaining=now;

    for (let i=0;i<10;i++){
        time=char(remaining%32)+time;
        remaining=Math.floor(remaining/32);
    }

    let suffix=""
    for (const byte of randomBytes(16)){
        suffix+=char(byte);
    }
    return time+suffix;
}

export const newAgencyId = (): string => `agc_${ulid()}`;
export const newClientId = (): string => `cli_${ulid()}`;
export const newReportId = (): string => `rep_${ulid()}`;
export const newMemoryId = (): string => `mem_${ulid()}`;
export const newConnectionId = (): string => `con_${ulid()}`;

export function hasPrefix(id:string,prefix:string):boolean{
    return id.startsWith(`${prefix}_`)&&id.length===prefix.length+27;
}