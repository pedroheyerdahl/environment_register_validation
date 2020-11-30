-- teste 01
-- Seleciona imóveis que tenham mais de 4 módulos fiscais, de acordo com o campo mod_fiscal
UPDATE entrega_XX.lote_atp la
SET teste_01 = 
    (
    SELECT 
        CASE 
             WHEN la.mod_fiscal > 4 
             THEN TRUE
             WHEN la.mod_fiscal <= 4 
             THEN FALSE
             ELSE NULL 
        END
    );

-- teste 02
-- Seleciona imóveis do lote com sobreposição de perímetro
DROP TABLE IF EXISTS entrega_XX.teste_02;

CREATE TABLE entrega_XX.teste_02 AS
      SELECT la1.cod_imovel,
             la1.cod_emp,
             la2.cod_emp AS sobrepoe,
             la1.municipio,
             la1.lote,
             ST_Intersection(la1.geom, la2.geom) AS geom,
             ST_Area(ST_Intersection(la1.geom, la2.geom)) AS area_m2
        FROM entrega_XX.lote_atp la1 
  INNER JOIN entrega_XX.lote_atp la2 
          ON 
             (
             la1.geom && la2.geom 
             AND ST_Intersects(la1.geom, la2.geom)
             ) 
       WHERE la1.cod_imovel != la2.cod_imovel
	     AND ST_Area(ST_Intersection(la1.geom, la2.geom)) > 100;

UPDATE entrega_XX.lote_atp 
   SET teste_02 = 
       (
       CASE
            WHEN entrega_XX.lote_atp.cod_imovel IN 
                 (
                 SELECT t02.cod_imovel 
                   FROM entrega_XX.teste_02 AS t02 
                 )
            THEN TRUE 
            ELSE FALSE 
        END
        );

-- Teste 03
-- Seleciona imóveis do lote cuja sobreposição com imóveis da base seja superior a 10% da área do menor imóvel envolvido
DROP TABLE IF EXISTS entrega_XX.teste_03;

CREATE TABLE entrega_XX.teste_03 AS
      SELECT la.cod_imovel,
             la.cod_emp,
             ba.cod_emp AS emp_sobrep,
             ba.cod_imovel AS im_sobrep,
             la.municipio,
             la.lote,
	         ST_Multi(ST_Union(ST_Intersection(la.geom, ba.geom))) AS geom
        FROM entrega_XX.lote_atp AS la
  INNER JOIN entrega_XX.base_atp AS ba 
          ON la.geom && ba.geom
             AND la.cod_imovel != ba.cod_imovel
             AND 
               (
			     (ST_Area(ST_Intersection(la.geom, ba.geom))/ST_Area(la.geom)) >.1 
                 OR (ST_Area(ST_Intersection(la.geom, ba.geom))/ST_Area(ba.geom)) >.1
               )
    GROUP BY la.cod_imovel, la.cod_emp, la.municipio, la.lote, ba.cod_emp, ba.cod_imovel;
                
UPDATE entrega_XX.lote_atp 
   SET teste_03 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT cod_imovel 
              FROM entrega_XX.teste_03 
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );
-- Teste 04
-- Seleciona imóveis limítrofes inscritos sob mesmo CPF / CNPJ.
DROP TABLE IF EXISTS entrega_XX.teste_04;

CREATE TABLE entrega_XX.teste_04 AS
      SELECT la.cod_imovel,
             la.cod_emp,
             la.municipio,
             la.lote,
             ST_Multi(ST_Union(ST_Intersection(la.geom, ba.geom))) as geom        
        FROM entrega_XX.lote_atp la
  INNER JOIN entrega_XX.base_atp ba 
          ON 
             (
             la.geom && ba.geom 
             AND ST_Intersects(la.geom, ba.geom)
             )
       WHERE la.doc_proprietario = ba.doc_proprietario
             AND la.cod_imovel != ba.cod_imovel
	GROUP BY la.cod_imovel, la.cod_emp, la.municipio, la.lote;

UPDATE entrega_XX.lote_atp 
   SET teste_04 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT cod_imovel 
              FROM entrega_XX.teste_04 
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );

-- Teste 05
-- Seleciona imóveis com áreas sem uso do solo superiores a 1ha ou 10% da área total da propriedade
DROP TABLE IF EXISTS entrega_XX.teste_05;

CREATE TABLE entrega_XX.teste_05 AS
      SELECT la.cod_imovel,
             la.cod_emp,
             la.municipio,
             la.lote,
             ST_Difference(la.geom, us.geom) AS geom
        FROM entrega_XX.lote_atp AS la
  INNER JOIN entrega_XX.uso_solo AS us 
          ON 
             (
             la.geom && us.geom 
             AND ((ST_Area(ST_Difference(la.geom, us.geom))) > 10000) 
             OR (ST_Area(ST_Difference(la.geom, us.geom))/(ST_Area(la.geom))>0.1)
             )
       WHERE la.cod_imovel = us.cod_imovel;      

INSERT INTO entrega_XX.teste_05
     SELECT la.cod_imovel,
            la.cod_emp,
            la.municipio,
            la.lote,
            la.geom
       FROM entrega_XX.lote_atp AS la
  LEFT JOIN entrega_XX.uso_solo AS us
         ON la.cod_imovel = us.cod_imovel
      WHERE us.cod_imovel IS NULL;
                
UPDATE entrega_XX.lote_atp 
   SET teste_05 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT cod_imovel 
              FROM entrega_XX.teste_05 
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );

-- Teste 06
-- Seleciona imóveis com total de APP sem caracterização de uso do solo superior a 100m²
DROP TABLE IF EXISTS entrega_XX.teste_06;

CREATE TABLE entrega_XX.teste_06 AS
      SELECT lp.cod_imovel,
             lp.cod_emp,
             lp.municipio,
             lp.lote,
             ST_Difference(lp.geom, us.geom) AS geom
        FROM entrega_XX.lote_app AS lp
  INNER JOIN entrega_XX.uso_solo AS us 
          ON 
             (
             lp.geom && us.geom 
             AND ST_Area(ST_Difference(lp.geom, us.geom)) > 100
             )
       WHERE lp.cod_imovel = us.cod_imovel;
                              
INSERT INTO entrega_XX.teste_06   
     SELECT lp.cod_imovel,
            lp.cod_emp,
            lp.municipio,
            lp.lote
       FROM entrega_XX.lote_app AS lp
  LEFT JOIN entrega_XX.uso_solo AS us
         ON lp.cod_imovel = us.cod_imovel
      WHERE us.cod_imovel IS NULL;
             
UPDATE entrega_XX.lote_atp 
   SET teste_06 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT cod_imovel 
              FROM entrega_XX.teste_06 
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );

--Teste 07
--Seleciona imóveis com massa d'água não caracterizada total maior que 1000m²
DROP TABLE IF EXISTS entrega_XX.teste_07;

CREATE TABLE entrega_XX.teste_07 AS
      SELECT ih.cod_imovel,
             ih.cod_emp,
             ih.municipio,
             ih.lote,
             ST_Multi(ST_Union(ST_Difference(ih.geom, lh.geom))) AS geom
        FROM entrega_XX.iema_hidro_int AS ih
  INNER JOIN entrega_XX.lote_hidro AS lh 
          ON ST_Area(ST_Difference(ih.geom, lh.geom)) > 1000
       WHERE ih.cod_imovel = lh.cod_imovel
    GROUP BY ih.cod_imovel, ih.cod_emp, ih.municipio, ih.lote;
				  
INSERT INTO entrega_XX.teste_07  
     SELECT ih.cod_imovel,
            ih.cod_emp,
            ih.municipio,
            ih.lote,
	        ih.geom
       FROM entrega_XX.iema_hidro_int AS ih
  LEFT JOIN entrega_XX.lote_hidro AS lh
         ON ih.cod_imovel = lh.cod_imovel
      WHERE lh.cod_imovel IS NULL
            AND ih.area_m2 > 1000;
             
UPDATE entrega_XX.lote_atp 
   SET teste_07 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT cod_imovel 
              FROM entrega_XX.teste_07 
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );

-- Teste 08
-- Seleciona imóveis com AVN não caracterizada total maior que 5000m²
DROP TABLE IF EXISTS entrega_XX.teste_08;

CREATE TABLE entrega_XX.teste_08 AS
      SELECT iv.cod_imovel,
             iv.cod_emp,
             iv.municipio,
             iv.lote,
             ST_Multi(ST_Union(ST_Difference(iv.geom, lv.geom))) AS geom
        FROM entrega_XX.iema_avn_int AS iv
  INNER JOIN entrega_XX.lote_avn AS lv 
          ON ST_Area(ST_Difference(iv.geom, lv.geom)) > 5000
       WHERE iv.cod_imovel = lv.cod_imovel
    GROUP BY iv.cod_imovel, iv.cod_emp, iv.municipio, iv.lote;

				  
INSERT INTO entrega_XX.teste_08  
     SELECT iv.cod_imovel,
            iv.cod_emp,
            iv.municipio,
            iv.lote,
            iv.geom
       FROM entrega_XX.iema_avn_int AS iv
  LEFT JOIN entrega_XX.lote_avn AS lv 
         ON iv.cod_imovel = lv.cod_imovel
      WHERE lv.cod_imovel IS NULL
            AND iv.area_m2 > 5000; 
             
UPDATE entrega_XX.lote_atp 
   SET teste_08 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT cod_imovel 
              FROM entrega_XX.teste_08 
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );

-- Teste 09
-- Seleciona imoveis que apresentam sobreposição de arl superior a 500m²
DROP TABLE IF EXISTS entrega_XX.teste_09;

CREATE TABLE entrega_XX.teste_09 AS
      SELECT lr.cod_imovel,
             lr.cod_emp,
             lr.municipio,
             lr.lote,
	         ST_Multi(ST_Union(ST_Intersection(lr.geom, br.geom))) AS geom
        FROM entrega_XX.lote_arl lr
  INNER JOIN entrega_XX.base_arl br 
          ON lr.geom && br.geom
         AND lr.cod_imovel != br.cod_imovel
         AND ST_Area(ST_Intersection(lr.geom, br.geom)) > 500
    GROUP BY lr.cod_imovel, lr.cod_emp, lr.municipio, lr.lote;
		 
UPDATE entrega_XX.lote_atp 
   SET teste_09 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT cod_imovel 
              FROM entrega_XX.teste_09 
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );

-- Teste 10
-- Seleciona imóveis que tem AVN menor que 20% da ATP e não marcaram toda vegetação como ARL, em atenção ao art. 67 da Lei 12651/2012
DROP TABLE IF EXISTS  entrega_XX.teste_10;

CREATE TABLE entrega_XX.teste_10 AS
     SELECT cod_imovel_avn AS cod_imovel,
            cod_emp_avn AS cod_emp,
            municipio_avn AS municipio,
            lote_avn AS lote,
            ST_Difference(geom_lv, lr.geom) AS geom
       FROM entrega_XX.lote_arl AS lr
INNER JOIN 
           (
           SELECT la.cod_imovel AS cod_imovel_avn,
                  la.cod_emp AS cod_emp_avn,
                  la.lote AS lote_avn,
                  la.municipio AS municipio_avn,
                  lv.geom AS geom_lv
             FROM entrega_XX.lote_atp AS la
       INNER JOIN entrega_XX.lote_avn AS lv
               ON la.cod_imovel = lv.cod_imovel
              AND ST_Area(lv.geom)/ST_Area(la.geom) < 0.2
           )
		 AS avn_abaixo_20_pct
	     ON lr.cod_imovel = cod_imovel_avn
	    AND ST_Area(ST_Difference(geom_lv, lr.geom)) > 1;

INSERT INTO entrega_XX.teste_10  
     SELECT lv.cod_imovel,
            lv.cod_emp,
            lv.municipio,
            lv.lote,
	        lv.geom
       FROM entrega_XX.lote_avn AS lv
  LEFT JOIN entrega_XX.lote_arl AS lr
         ON lv.cod_imovel = lr.cod_imovel
      WHERE lr.cod_imovel IS NULL;

UPDATE entrega_XX.lote_atp 
   SET teste_10 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT t10.cod_imovel 
              FROM entrega_XX.teste_10 AS t10
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );

-- Teste 11
-- Seleciona imóveis que tem AVN maior que 20% da ATP mas tem ARL menor que 20%, descumprindo o art. 12 da Lei 12.651/2012
DROP TABLE IF EXISTS entrega_XX.teste_11;

CREATE TABLE entrega_XX.teste_11 AS
      SELECT cod_imovel,
             cod_emp,
             municipio,
             lote,
             ST_Difference(geom_avn, geom_arl) AS geom
        FROM
              (
              --seleciona imoveis cuja avn é >= 20% atp
              SELECT la.cod_imovel,
                     la.cod_emp,
                     la.municipio,
                     la.lote,
                     lv.geom AS geom_avn 
                FROM entrega_XX.lote_atp AS la
          INNER JOIN entrega_XX.lote_avn as lv
                  ON la.cod_imovel=lv.cod_imovel
                 AND ST_Area(lv.geom)/ST_Area(la.geom)>=0.2
              ) 
           AS avn_pct
   INNER JOIN
              (
              --seleciona imoveis cuja arl sobre avn é <= 20% atp
              SELECT la.cod_imovel AS cod_imovel_arl_int_avn_menor_20_pct,
				     geom_arl_dentro_avn,
                     geom_arl
                FROM entrega_XX.lote_atp AS la
          INNER JOIN
                     (
                     --seleciona arl dentro de avn
                     SELECT lv.cod_imovel AS cod_imovel_arl_dentro_avn,
                            ST_Intersection(lv.geom, lr.geom) AS geom_arl_dentro_avn,
                            lr.geom AS geom_arl
                       FROM entrega_XX.lote_avn AS lv
                 INNER JOIN entrega_XX.lote_arl AS lr 
                         ON lv.cod_imovel = lr.cod_imovel
                     ) 
                  AS arl_int_avn_menor_20_pct 
                  ON la.cod_imovel=cod_imovel_arl_dentro_avn
                 AND ST_Area(geom_arl_dentro_avn)/ST_Area(la.geom)<=0.2
              )
           AS arl_int_app 
           ON cod_imovel = cod_imovel_arl_int_avn_menor_20_pct
		   AND ST_Area(ST_Difference(geom_avn, geom_arl)) > 0.1
		   ;     

UPDATE entrega_XX.lote_atp 
   SET teste_11 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT cod_imovel 
              FROM entrega_XX.teste_11 
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );

-- Teste 12
-- Verifica a existência de sobreposição indevida de ARL em APP (imóvel tem AVN excedente fora de APP)
DROP TABLE IF EXISTS lote_avn_fora_app;
DROP TABLE IF EXISTS entrega_XX.teste_12;

CREATE TEMPORARY TABLE lote_avn_fora_app AS
                SELECT lv.cod_imovel,
                       lv.cod_emp,
                       ST_Difference(lv.geom, lp.geom) AS geom
                  FROM entrega_XX.lote_avn AS lv
            INNER JOIN entrega_XX.lote_app AS lp 
                    ON lv.cod_imovel = lp.cod_imovel
              ORDER BY cod_imovel;

CREATE TABLE entrega_XX.teste_12 AS
      SELECT cod_imovel,
             cod_emp,
             municipio,
             lote,
             ST_Difference(geom_arl, avn_fora_app_geom) AS geom
        FROM
              (
              --seleciona imoveis cuja avn fora de app é >= 20% atp
              SELECT la.cod_imovel,
                     la.cod_emp,
                     la.municipio,
                     la.lote,
                     lv.geom AS avn_fora_app_geom 
                FROM entrega_XX.lote_atp AS la
          INNER JOIN lote_avn_fora_app as lv
                  ON la.cod_imovel=lv.cod_imovel
                 AND ST_Area(lv.geom)/ST_Area(la.geom)>=0.2
              ) 
           AS avn_fora_app_pct
   INNER JOIN
              (
              --seleciona imoveis cuja arl sobre avn_fora_app é <= 20% atp
              SELECT la.cod_imovel AS cod_imovel_arl_int_avn_menor_20_pct,
				     geom_arl_dentro_avn,
                     geom_arl
                FROM entrega_XX.lote_atp AS la
          INNER JOIN
                     (
                     --seleciona arl dentro de avn_fora_app
                     SELECT lv.cod_imovel AS cod_imovel_arl_dentro_avn,
                            ST_Intersection(lv.geom, lr.geom) AS geom_arl_dentro_avn,
                            lr.geom AS geom_arl
                       FROM lote_avn_fora_app AS lv
                 INNER JOIN entrega_XX.lote_arl AS lr 
                         ON lv.cod_imovel = lr.cod_imovel
                     ) 
                  AS arl_int_avn_menor_20_pct 
                  ON la.cod_imovel=cod_imovel_arl_dentro_avn
                 AND ST_Area(geom_arl_dentro_avn)/ST_Area(la.geom)<=0.2
              )
           AS arl_int_app 
           ON cod_imovel = cod_imovel_arl_int_avn_menor_20_pct
		   AND ST_Area(ST_Difference(geom_arl, avn_fora_app_geom)) > 0.1
		   ;     

UPDATE entrega_XX.lote_atp 
   SET teste_12 = 
       (
       CASE
       WHEN entrega_XX.lote_atp.cod_imovel IN 
            (
            SELECT cod_imovel 
              FROM entrega_XX.teste_12 
            )
       THEN TRUE 
       ELSE FALSE 
        END
        );

UPDATE entrega_XX.lote_atp AS la
   SET geral = 
       (
       CASE 
            WHEN la.cod_imovel IN 
                 (
                 --seleciona imoveis que falharam em ao menos um dos testes
                 SELECT la.cod_imovel 
                   FROM entrega_XX.lote_atp AS er
                  WHERE la.teste_01 = true 
                        OR la.teste_02 = true
                        OR la.teste_03 = true 
                        OR la.teste_04 = true
                        OR la.teste_05 = true
                        OR la.teste_06 = true
                        OR la.teste_07 = true
                        OR la.teste_08 = true
                        OR la.teste_09 = true
                        OR la.teste_10 = true
                        OR la.teste_11 = true
                        OR la.teste_12 = true
                 )
            THEN TRUE 
            ELSE FALSE
        END
        );

SELECT cod_imovel,
       cod_emp,
       municipio,
       lote,
       teste_01,
       teste_02,
	   teste_03,
       teste_04,
       teste_05,
       teste_06,
       teste_07,
       teste_08,
       teste_09,
       teste_10,
       teste_11,
       teste_12,
       geral
  FROM entrega_XX.lote_atp