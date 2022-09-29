# [Стрим 3](https://www.youtube.com/watch?v=nQuFMSIbX04). Процедурная анимация - скачущий мячик

## Отличия от контента, показанного в стриме
* рандомные значения выгружены в tecoord1 меша, чтоб в texcoord0 были реальные увишки - для д/з с текстурой.
* в hou-файле удалён мой инхаузный ассет, генерящий шарик с топологией куба - вместо этого меш заморожен, чтоб желающие потыкаться в Houdini могли это сделать.
* в шейдере добавлены более подробные комментарии.

## Задания для практики (д/з)
* Добавить мячикам текстуры, помножать их на vertex color. UV-шки - в texcoord0.
* Заставить мячик двигаться не только по Y, но и по X/Z, просто двумя синусами с разной частотой - чтоб мячики не скакали на месте.
* Заставить мячики скакать на разную высоту (спойлер: двух рандомов - достаточно, чтоб из них всего за две операции получить третий).
* заставить мячики крутиться. Вот функция для вычисления матрицы поворота. За ось можно взять цвет мячика, только привести его к диапазону [-1, 1] и нормализовать вектор.

```hlsl
// Rotate around custom axis.
// The axis vector has to be normalized.
float3x3 rotMtxCustomAxis (float angleRad, float3 axis) {
	float angSin, angCos;
	sincos(angleRad, angSin, angCos);
	
	float invCos = 1.0 - angCos;
	
	// intermediate:
	// float intXY = invCos * axis.x * axis.y;
	// float intXZ = invCos * axis.x * axis.z;
	// float intYZ = invCos * axis.y * axis.z;
	
	float3 invCos_XY_XZ_YZ = invCos * axis.xxy * axis.yzz;
	
	float3 sinVec = axis * angSin;
	float3 negSinVec = -sinVec;
	float3 invCos_axisSq = invCos * axis * axis;
	
	// return float3x3 (
	// 	angCos + invCos * axis.x * axis.x,   invCos_XY_XZ_YZ.x - sinVec.z,   invCos_XY_XZ_YZ.y + sinVec.y,
	// 	invCos_XY_XZ_YZ.x + sinVec.z,   angCos + invCos * axis.y * axis.y,   invCos_XY_XZ_YZ.z - sinVec.x,
	// 	invCos_XY_XZ_YZ.y - sinVec.y,   invCos_XY_XZ_YZ.z + sinVec.x,   angCos + invCos * axis.z * axis.z
	// );
	
	return
		float3x3(
			angCos,              invCos_XY_XZ_YZ.x,   invCos_XY_XZ_YZ.y,
			invCos_XY_XZ_YZ.x,   angCos,              invCos_XY_XZ_YZ.z,
			invCos_XY_XZ_YZ.y,   invCos_XY_XZ_YZ.z,   angCos
		)
		+
		float3x3(
			invCos_axisSq.x,   negSinVec.z,       sinVec.y,
			sinVec.z,          invCos_axisSq.y,   negSinVec.x,
			negSinVec.y,       sinVec.x,          invCos_axisSq.z
		)
	;
}
```
