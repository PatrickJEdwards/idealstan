// chunk giving a hiearchical TS prior to legislators/persons

//add basic integrated time-series prior
for(t in 2:T) {

    L_tp1[t] ~normal(L_full + L_AR1 .* L_tp1[t - 1] + legis_pred[t, 1:(num_legis), ] * legis_x,
      legis_sd/time_sd);
}
