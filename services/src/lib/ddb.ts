import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";


const base= new DynamoDBClient({
    maxAttempts:3
});


export const ddb=DynamoDBDocumentClient.from(base,{
    marshallOptions:{
        removeUndefinedValues:true,
        convertClassInstanceToMap:false
    }
})