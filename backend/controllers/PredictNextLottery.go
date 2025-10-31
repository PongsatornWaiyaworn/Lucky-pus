package controllers

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/gin-gonic/gin"
)

type PastDraw struct {
	FirstPrize      string   `json:"first_prize"`
	ThreeDigitFront []string `json:"three_digit_front"`
	ThreeDigitBack  []string `json:"three_digit_back"`
	TwoDigitBack    string   `json:"two_digit_back"`
	DrawDate        string   `json:"draw_date"`
}

type LatestAPIResponse struct {
	Status   string `json:"status"`
	Response struct {
		Date   string `json:"date"`
		Prizes []struct {
			ID     string   `json:"id"`
			Name   string   `json:"name"`
			Number []string `json:"number"`
		} `json:"prizes"`
		RunningNumbers []struct {
			ID     string   `json:"id"`
			Name   string   `json:"name"`
			Number []string `json:"number"`
		} `json:"runningNumbers"`
	} `json:"response"`
}

func fetchLatestDraw() (PastDraw, error) {
	resp, err := http.Get("https://lotto.api.rayriffy.com/latest")
	if err != nil {
		return PastDraw{}, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return PastDraw{}, fmt.Errorf("status %d", resp.StatusCode)
	}

	body, _ := ioutil.ReadAll(resp.Body)
	var apiResp LatestAPIResponse
	if err := json.Unmarshal(body, &apiResp); err != nil {
		return PastDraw{}, err
	}

	latest := PastDraw{
		DrawDate: apiResp.Response.Date,
	}

	for _, prize := range apiResp.Response.Prizes {
		switch prize.ID {
		case "prizeFirst":
			if len(prize.Number) > 0 {
				latest.FirstPrize = prize.Number[0]
			}
		case "runningNumberFrontThree": // เลขหน้า 3 ตัว
			latest.ThreeDigitFront = prize.Number
		case "runningNumberBackThree": // เลขท้าย 3 ตัว
			latest.ThreeDigitBack = prize.Number
		case "runningNumberBackTwo": // เลขท้าย 2 ตัว
			if len(prize.Number) > 0 {
				latest.TwoDigitBack = prize.Number[0]
			}
		}
	}

	return latest, nil
}

func PredictNextLottery(c *gin.Context) {
	var lotteryHistory = []PastDraw{
		{FirstPrize: "059696", ThreeDigitFront: []string{"531", "955"}, ThreeDigitBack: []string{"476", "889"}, TwoDigitBack: "61", DrawDate: "16/10/2568"},
		{FirstPrize: "876978", ThreeDigitFront: []string{"843", "532"}, ThreeDigitBack: []string{"280", "605"}, TwoDigitBack: "77", DrawDate: "1/10/2568"},
		{FirstPrize: "074646", ThreeDigitFront: []string{"512", "740"}, ThreeDigitBack: []string{"308", "703"}, TwoDigitBack: "58", DrawDate: "16/9/2568"},
		{FirstPrize: "506356", ThreeDigitFront: []string{"131", "012"}, ThreeDigitBack: []string{"022", "209"}, TwoDigitBack: "31", DrawDate: "1/9/2568"},
		{FirstPrize: "994865", ThreeDigitFront: []string{"247", "602"}, ThreeDigitBack: []string{"834", "989"}, TwoDigitBack: "63", DrawDate: "16/8/2568"},
		{FirstPrize: "811852", ThreeDigitFront: []string{"142", "525"}, ThreeDigitBack: []string{"512", "891"}, TwoDigitBack: "50", DrawDate: "1/8/2568"},
		{FirstPrize: "245324", ThreeDigitFront: []string{"995", "171"}, ThreeDigitBack: []string{"084", "336"}, TwoDigitBack: "26", DrawDate: "16/7/2568"},
		{FirstPrize: "949246", ThreeDigitFront: []string{"680", "169"}, ThreeDigitBack: []string{"918", "261"}, TwoDigitBack: "91", DrawDate: "1/7/2568"},
		{FirstPrize: "507392", ThreeDigitFront: []string{"243", "017"}, ThreeDigitBack: []string{"299", "736"}, TwoDigitBack: "06", DrawDate: "16/6/2568"},
		{FirstPrize: "559352", ThreeDigitFront: []string{"349", "134"}, ThreeDigitBack: []string{"307", "044"}, TwoDigitBack: "20", DrawDate: "1/6/2568"},
		{FirstPrize: "251309", ThreeDigitFront: []string{"109", "231"}, ThreeDigitBack: []string{"965", "631"}, TwoDigitBack: "87", DrawDate: "16/5/2568"},
		{FirstPrize: "213388", ThreeDigitFront: []string{"826", "116"}, ThreeDigitBack: []string{"167", "662"}, TwoDigitBack: "06", DrawDate: "2/5/2568"},
		{FirstPrize: "266227", ThreeDigitFront: []string{"413", "254"}, ThreeDigitBack: []string{"474", "760"}, TwoDigitBack: "85", DrawDate: "16/4/2568"},
		{FirstPrize: "669687", ThreeDigitFront: []string{"635", "760"}, ThreeDigitBack: []string{"180", "666"}, TwoDigitBack: "36", DrawDate: "1/4/2568"},
		{FirstPrize: "757563", ThreeDigitFront: []string{"595", "927"}, ThreeDigitBack: []string{"457", "309"}, TwoDigitBack: "32", DrawDate: "16/3/2568"},
		{FirstPrize: "818894", ThreeDigitFront: []string{"139", "530"}, ThreeDigitBack: []string{"656", "781"}, TwoDigitBack: "54", DrawDate: "1/3/2568"},
		{FirstPrize: "847377", ThreeDigitFront: []string{"268", "613"}, ThreeDigitBack: []string{"652", "001"}, TwoDigitBack: "50", DrawDate: "16/2/2568"},
		{FirstPrize: "558700", ThreeDigitFront: []string{"285", "418"}, ThreeDigitBack: []string{"685", "824"}, TwoDigitBack: "51", DrawDate: "1/2/2568"},
		{FirstPrize: "807779", ThreeDigitFront: []string{"699", "961"}, ThreeDigitBack: []string{"448", "477"}, TwoDigitBack: "23", DrawDate: "17/1/2568"},
		{FirstPrize: "730209", ThreeDigitFront: []string{"446", "065"}, ThreeDigitBack: []string{"376", "297"}, TwoDigitBack: "51", DrawDate: "2/1/2568"},
	}

	latestDraw, err := fetchLatestDraw()
	if err == nil {
		lotteryHistory = append(lotteryHistory, latestDraw)
	}

	type PosCount map[int]map[rune]float64
	countDigits := func(numbers []string, weight float64) PosCount {
		freq := make(PosCount)
		for _, num := range numbers {
			for i, d := range num {
				if freq[i] == nil {
					freq[i] = make(map[rune]float64)
				}
				freq[i][d] += weight
			}
		}
		return freq
	}

	firstCount := make(PosCount)
	front3Count := make(PosCount)
	back3Count := make(PosCount)
	back2Count := make(PosCount)

	for idx, draw := range lotteryHistory {
		weight := 1.0
		if idx == len(lotteryHistory)-1 {
			weight = 1.0
		}

		ff := countDigits([]string{draw.FirstPrize}, weight)
		for pos, m := range ff {
			if firstCount[pos] == nil {
				firstCount[pos] = make(map[rune]float64)
			}
			for k, v := range m {
				firstCount[pos][k] += v
			}
		}
		f3 := countDigits(draw.ThreeDigitFront, weight)
		for pos, m := range f3 {
			if front3Count[pos] == nil {
				front3Count[pos] = make(map[rune]float64)
			}
			for k, v := range m {
				front3Count[pos][k] += v
			}
		}
		b3 := countDigits(draw.ThreeDigitBack, weight)
		for pos, m := range b3 {
			if back3Count[pos] == nil {
				back3Count[pos] = make(map[rune]float64)
			}
			for k, v := range m {
				back3Count[pos][k] += v
			}
		}
		b2 := countDigits([]string{draw.TwoDigitBack}, weight)
		for pos, m := range b2 {
			if back2Count[pos] == nil {
				back2Count[pos] = make(map[rune]float64)
			}
			for k, v := range m {
				back2Count[pos][k] += v
			}
		}
	}

	selectTop := func(count PosCount) string {
		result := ""
		for i := 0; i < len(count); i++ {
			maxProb := 0.0
			var top rune
			total := 0.0
			for _, v := range count[i] {
				total += v
			}
			for d, v := range count[i] {
				prob := v / total
				if prob > maxProb {
					maxProb = prob
					top = d
				}
			}
			result += string(top)
		}
		return result
	}

	prediction := gin.H{
		"first_prize_prediction": selectTop(firstCount),
		"three_digit_front":      selectTop(front3Count),
		"three_digit_back":       selectTop(back3Count),
		"two_digit_back":         selectTop(back2Count),
	}

	c.JSON(200, prediction)
}
