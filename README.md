# environment_register_validation
Postgis/PyQgis geographic project validation/visualization suite

TO DO:
Change inner to left join on create and populate imóveis  lote_atp 

Incluir verificação de (primeira e?) ultima inscrição retificada na tabela sicar_xx.atp usando:


WITH retificados AS (
                SELECT s.cod_imovel,
                       MAX(s.data_emissao) AS maximo,
                       MIN(s.data_emissao) AS minimo 
                  FROM sicar_07.simlam s 
                 WHERE s.cod_imovel IS NOT NULL
                       AND s.stat_sicar = 'arquivo retificado'
              GROUP BY s.cod_imovel)

SELECT x.cod_imovel, n.minimo AS primeiro_envio, n.maximo AS ultimo_envio, x.data_envio FROM entrega_07.lote_atp x LEFT JOIN tab_min n ON n.cod_imovel = x.cod_imovel
WHERE n.minimo != n.maximo
ORDER BY ultimo_envio
