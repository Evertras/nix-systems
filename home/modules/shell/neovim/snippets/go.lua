return {
  s('gomega-noerror', t(
  'Expect(err).ToNot(HaveOccurred(), "Should not have errored")'
  )),
  s('ginkgo-boilerplate', t([[
package idk

import (
  . "github.com/onsi/ginkgo/v2"
  . "github.com/onsi/ginkgo/v2"
)

var _ = Describe("Something", func() {
  It("should run this", func() {
    Expect(true).To(BeTrue())
  })
})
]]))
}
