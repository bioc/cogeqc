
#----Load data------------------------------------------------------------------
data(synnet)

#----Start tests----------------------------------------------------------------
test_that("fit_sft() returns a numeric vector of R squared values", {

    rsquared <- fit_sft(synnet)

    expect_equal(class(rsquared), "numeric")
})

test_that("assess_synnet() works", {
    x <- assess_synnet(synnet)

    # Simulated synteny network without cols 'anchor1' and 'anchor2'
    sim_synnet <- matrix(c(1,2,3,4), ncol = 4)


    expect_equal(ncol(x), 4)
    expect_equal(names(x), c("CC", "Node_count", "Rsquared", "Score"))
    expect_error(assess_synnet(sim_synnet))
})

test_that("assess_synnet_list() returns a data frame", {
    net1 <- synnet
    net2 <- synnet[-sample(1:10000, 500), ]
    net3 <- synnet[-sample(1:10000, 1000), ]

    # Test 1: check if it works
    synnet_list <- list(net1 = net1, net2 = net2, net3 = net3)
    x <- assess_synnet_list(synnet_list)

    # Test 2: check if it can handle unnamed lists
    synnet_list2 <- synnet_list
    names(synnet_list2) <- NULL
    x2 <- assess_synnet_list(synnet_list2)

    expect_equal(class(x), "data.frame")
    expect_equal(ncol(x), 5)
    expect_true("Network" %in% names(x))

    expect_equal(class(x2), "data.frame")

    expect_error(assess_synnet_list(synnet))
})
