export interface HealthResponse{
    status:"ok";
    service:"numeraft-api";
    environment:string;
    timestamp:string;
    requestId:string
}