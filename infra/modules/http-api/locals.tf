locals{
    route_parts={
        for key,cfg in var.routes: key=>{
            method = split(" ", key)[0]
            path   = regexreplace(split(" ", key)[1], "\\{[^}]+\\}", "*")
        }
    }
}